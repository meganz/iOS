@testable import ContentLibraries
import Foundation
import MEGADomain
import MEGAPreferenceMocks
import Testing
import UIKit

/// The drag advances through three calls the pan recognizer makes — begin, extend, end — and the
/// auto-scroll ticks come through the same extend, so a check placed there cannot be reached by one
/// path and missed by the other. These drive those calls directly: index paths stand in for where a
/// finger is, which is all the coordinator reads from a gesture anyway.
@MainActor
@Suite("Photo grid drag selection")
struct PhotoLibraryCollectionViewCoordinatorDragTests {

    @Test("A drag extended after the grid was re-laid out ends, rather than selecting by positions that moved")
    func dragEndsWhenTheRenderedLayoutMoves() async {
        let handler = MockPositionalSelectionHandler()
        let sut = await Self.makeSUT(library: Self.skeleton(layoutVersion: 0), handler: handler)

        sut.coordinator.beginDragSelection(at: Self.indexPath(0))
        #expect(handler.begunGestures == 1)

        // What a reshape looks like from here: same three slots, a layout that is no longer the one
        // the drag's index paths were read against.
        sut.contentViewModel.library = Self.skeleton(layoutVersion: 1)
        await Self.gridToCatchUp()

        let extended = sut.coordinator.extendDragSelection(to: Self.indexPath(2))

        #expect(extended == false)
        #expect(handler.endedGestures.count == 1)
        // Only the cell the drag began on was ever marked; the band never reached slot 2.
        #expect(handler.applied.map(\.position.flatIndex) == [0])
    }

    @Test("Filling a slot mid-drag does not end the drag — the layout has not moved")
    func hydrationDoesNotEndTheDrag() async {
        let handler = MockPositionalSelectionHandler()
        let sut = await Self.makeSUT(library: Self.skeleton(layoutVersion: 0), handler: handler)

        sut.coordinator.beginDragSelection(at: Self.indexPath(0))
        sut.contentViewModel.library = sut.contentViewModel.library
            .replacingPhotos(from: 1, with: [Self.loadedPhoto])
        await Self.gridToCatchUp()

        #expect(sut.coordinator.extendDragSelection(to: Self.indexPath(2)))
        #expect(handler.endedGestures.isEmpty)
    }

    @Test("A cell that loaded mid-drag is restored from the handler's record, not from the handles held at the start")
    func shrinkBackAsksTheHandlerAboutACellThatLoaded() async {
        // Slot 1 was marked before the drag, while it was still a bare slot, and its photo arrives
        // during the drag. The handles selected at `.began` cannot say anything about that node —
        // it did not exist yet — so shrinking back over it would clear a mark the user made.
        let handler = MockPositionalSelectionHandler()
        handler.baselineHandles = [Self.loadedPhoto.handle]
        let sut = await Self.makeSUT(library: Self.skeleton(layoutVersion: 0), handler: handler)

        sut.coordinator.beginDragSelection(at: Self.indexPath(0))
        sut.coordinator.extendDragSelection(to: Self.indexPath(1))

        sut.contentViewModel.library = sut.contentViewModel.library
            .replacingPhotos(from: 1, with: [Self.loadedPhoto])
        await Self.gridToCatchUp()

        sut.coordinator.extendDragSelection(to: Self.indexPath(0)) // slot 1 leaves the band

        #expect(handler.baselineHandleQueries == [Self.loadedPhoto.handle])
        #expect(sut.contentViewModel.selection.isPhotoSelected(Self.loadedPhoto))
    }

    @Test("A slot long-pressed before its photo arrived still starts the drag as its origin")
    func longPressMarkSurvivesTheSlotResolvingIntoANode() async {
        // The press landed on a bare slot, so the mark went to the handler by position. The photo
        // arrives before the finger moves, so `.began` sees a loaded cell — and must still read
        // the mark, or it would toggle the very cell the user is holding.
        let handler = MockPositionalSelectionHandler()
        handler.recentlyLongPressedPositions = [SelectionPosition(flatIndex: 0, layoutVersion: 0)]
        let sut = await Self.makeSUT(library: Self.skeleton(layoutVersion: 0), handler: handler)

        sut.contentViewModel.library = sut.contentViewModel.library
            .replacingPhotos(from: 0, with: [Self.loadedPhoto])
        await Self.gridToCatchUp()

        sut.coordinator.beginDragSelection(at: Self.indexPath(0))

        #expect(handler.consumedLongPressMarks == 1)
        // The long-press already marked it; the drag extends from there instead of toggling it.
        #expect(!sut.contentViewModel.selection.isPhotoSelected(Self.loadedPhoto))
        #expect(handler.applied.isEmpty)
    }

    @Test("Without a handler, shrink-back still restores from the handles the drag started with")
    func shrinkBackWithoutAHandlerIsUnchanged() async {
        let sut = await Self.makeSUT(library: Self.loadedLibrary(), handler: nil)
        let photos = sut.contentViewModel.library.allPhotos
        sut.contentViewModel.selection.selectPhoto(photos[1])

        sut.coordinator.beginDragSelection(at: Self.indexPath(0)) // unselected → the drag selects
        sut.coordinator.extendDragSelection(to: Self.indexPath(2))
        sut.coordinator.extendDragSelection(to: Self.indexPath(0)) // both shrink back off

        #expect(sut.contentViewModel.selection.isPhotoSelected(photos[1])) // selected before the drag
        #expect(!sut.contentViewModel.selection.isPhotoSelected(photos[2])) // was not
    }

    // MARK: - Helpers

    private struct SUT {
        let coordinator: PhotoLibraryCollectionViewCoordinator
        let contentViewModel: PhotoLibraryContentViewModel
    }

    private static let loadedPhoto = NodeEntity(
        name: "loaded.jpg", handle: 42, modificationTime: bucketDate)

    private static let bucketDate = Date(timeIntervalSince1970: 1_660_780_800) // 2022-08-18T00:00:00Z

    private static func indexPath(_ item: Int) -> IndexPath {
        IndexPath(item: item, section: 0)
    }

    /// Three slots in one day bucket, so day and month grouping both render a single section and an
    /// item index is a flat index.
    private static func skeleton(layoutVersion: Int) -> PhotoLibrary {
        PhotoLibrary.skeleton(from: [
            MediaDateSectionEntity(
                groupId: "2022-08-18", startDate: bucketDate, endDate: bucketDate, count: 3)
        ])
        .withLayoutVersion(layoutVersion)
    }

    private static func loadedLibrary() -> PhotoLibrary {
        (0..<3)
            .map { NodeEntity(name: "\($0).jpg", handle: HandleEntity($0 + 1), modificationTime: bucketDate) }
            .toPhotoLibrary(withSortType: .modificationDesc, in: .GMT)
    }

    private static func makeSUT(
        library: PhotoLibrary, handler: MockPositionalSelectionHandler?
    ) async -> SUT {
        ContentLibraries.configuration = .mockConfiguration()
        let contentViewModel = PhotoLibraryContentViewModel(library: library)
        contentViewModel.positionalSelectionHandler = handler
        contentViewModel.selection.editMode = .active
        let viewModel = PhotoLibraryModeAllCollectionViewModel(
            libraryViewModel: contentViewModel, preferenceUseCase: MockPreferenceUseCase())
        let coordinator = PhotoLibraryCollectionViewCoordinator(
            PhotoLibraryCollectionViewRepresenter(
                viewModel: viewModel, router: MockPhotoLibraryContentViewRouter()))
        coordinator.configureDataSource(
            for: UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout()))
        await gridToCatchUp()
        return SUT(coordinator: coordinator, contentViewModel: contentViewModel)
    }

    /// The sections reach the collection view through a debounce, and a library change reaches the
    /// sections through a hop of its own, so a test has to let the grid settle before it can act on
    /// what is rendered — which is the very lag this feature exists to cope with.
    private static func gridToCatchUp() async {
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}

@MainActor
private final class MockPhotoLibraryContentViewRouter: PhotoLibraryContentViewRouting {
    func card(for photoByYear: PhotoByYear) -> PhotoYearCard { fatalError("unused by drag selection") }
    func card(for photoByMonth: PhotoByMonth) -> PhotoMonthCard { fatalError("unused by drag selection") }
    func card(for photoByDay: PhotoByDay) -> PhotoDayCard { fatalError("unused by drag selection") }
    func openPhotoBrowser(for photo: NodeEntity, allPhotos: [NodeEntity]) {}
    func openCameraUploadSettings(viewModel: PhotoLibraryModeAllViewModel) {}
    func showTakenDownNodeAlert() {}
}
