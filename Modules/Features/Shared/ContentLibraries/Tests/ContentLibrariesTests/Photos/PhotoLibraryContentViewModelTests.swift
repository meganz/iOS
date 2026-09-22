@testable import ContentLibraries
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import Testing

struct PhotoLibraryContentViewModelTests {
    @MainActor
    @Test(arguments: [
        (PhotoLibraryContentMode.album, false),
        (.albumLink, false),
        (.library, true),
        (.mediaDiscovery, true),
        (.mediaDiscoveryFolderLink, true)
    ])
    func shouldShowPhotoLibraryPicker(mode: PhotoLibraryContentMode, expectedResult: Bool) {
        let sut = Self.makeSUT(contentMode: mode)
        #expect(sut.shouldShowPhotoLibraryPicker == expectedResult)
    }
    
    @MainActor
    @Test
    func testToggleSelectAllPhotos_onCalledAgain_shouldToggleBetweenSelectAllAndUnselectAll() throws {
        let photos = [NodeEntity(name: "a.png", handle: HandleEntity(1),
                                 modificationTime: try "2023-08-18T22:01:04Z".date),
                      NodeEntity(name: "b.png", handle: HandleEntity(2),
                                 modificationTime: try "2023-08-11T22:01:04Z".date)
        ]
        let library = photos.toPhotoLibrary(withSortType: .modificationDesc)
        let sut = Self.makeSUT(library: library, contentMode: .album)
        
        sut.toggleSelectAllPhotos()
        
        #expect(sut.selection.allSelected)
        #expect(Set(library.allPhotos) == Set(photos))
        
        sut.toggleSelectAllPhotos()
        
        #expect(sut.selection.allSelected == false)
        #expect(sut.selection.photos.isEmpty)
        #expect(library.allPhotos.isNotEmpty)
    }

    @MainActor
    @Test
    func toggleSelectAllPhotos_withSkeletonSlotsInTheLibrary_stillTogglesOff() throws {
        // Three slots, two of them filled: `toPhotoLibrary` cannot build this, since a placeholder
        // carries no name and so is not visual media to the mapper.
        let bucketDate = try "2023-08-18T00:00:00Z".date
        let photos = [NodeEntity(name: "a.png", handle: HandleEntity(1), modificationTime: bucketDate),
                      NodeEntity(name: "b.png", handle: HandleEntity(2), modificationTime: bucketDate)
        ]
        let library = PhotoLibrary
            .skeleton(from: [MediaDateSectionEntity(
                groupId: "2023-08-18", startDate: bucketDate, endDate: bucketDate, count: 3)])
            .replacingPhotos(from: 0, with: photos)
        let sut = Self.makeSUT(library: library, contentMode: .library)

        sut.toggleSelectAllPhotos()

        #expect(sut.selection.allSelected)
        // The slot is not selectable, so the selection is short of the library by one and the
        // count on its own cannot tell "everything is selected" from "something is missing".
        #expect(sut.selection.photos.count == photos.count)
        #expect(library.allPhotos.count == photos.count + 1)

        sut.toggleSelectAllPhotos()

        #expect(sut.selection.allSelected == false)
        #expect(sut.selection.photos.isEmpty)
    }
    
    @MainActor
    @Test(arguments: [
        [NodeEntity(name: "a.png", handle: HandleEntity(1), modificationTime: try "2023-08-18T22:01:04Z".date)],
        []
    ])
    func testIsPhotoLibraryEmpty_onPhotoLibraryContentChange_shouldReturnPhotoLibraryEmptyState(photos: [NodeEntity]) throws {
        let sut = Self.makeSUT(library: photos.toPhotoLibrary(withSortType: .modificationDesc))
        
        #expect(sut.isPhotoLibraryEmpty ==  photos.isEmpty)
    }
    
    @MainActor
    @Test
    func libraryViewModeChangeTrackAnalytics() {
        let tracker = MockTracker()
        let sut = Self.makeSUT(
            tracker: tracker)
        
        sut.selectedMode = .day
        sut.selectedMode = .month
        sut.selectedMode = .year
        sut.selectedMode = .all
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                MediaScreenDaysFilterSelectedEvent(),
                MediaScreenMonthsFilterSelectedEvent(),
                MediaScreenYearsFilterSelectedEvent(),
                MediaScreenAllFilterSelectedEvent()
            ]
        )
    }
    
    @MainActor
    @Test("The album link borrows the picker but not the Media screen's filter events")
    func libraryViewModeChangeOnAlbumLinkTracksNothing() {
        let tracker = MockTracker()
        let sut = Self.makeSUT(contentMode: .albumLink, tracker: tracker)
        
        sut.selectedMode = .day
        sut.selectedMode = .month
        sut.selectedMode = .year
        sut.selectedMode = .all
        
        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }
    
    @MainActor
    private static func makeSUT(
        library: PhotoLibrary = PhotoLibrary(),
        contentMode: PhotoLibraryContentMode = .library,
        configuration: PhotoLibraryContentConfiguration? = nil,
        tracker: some AnalyticsTracking = MockTracker()
    ) -> PhotoLibraryContentViewModel {
        .init(
            library: library,
            contentMode: contentMode,
            configuration: configuration,
            tracker: tracker
        )
    }
}
