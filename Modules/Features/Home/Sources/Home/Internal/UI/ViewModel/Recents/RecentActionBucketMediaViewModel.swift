import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

@MainActor
final class RecentActionBucketMediaViewModel: ObservableObject {
    let photoLibraryContentViewModel: PhotoLibraryContentViewModel

    @Published var bottomBarAction: RecentActionBottomBarAction?
    @Published var editMode: EditMode = .inactive
    @Published private(set) var navigationTitle: RecentActionBucketItemsNavigationTitle
    @Published private(set) var nodesAction: NodesAction?
    @Published private(set) var selectedPhotos: [HandleEntity: NodeEntity] = [:]
    @Published private(set) var bottomBarDisabled: Bool = false
    @Published private var bucket: RecentActionBucketEntity
    @Published private(set) var isBucketEmpty: Bool = false
    @Published private(set) var fileNoLongerAvailableSnackBar: SnackBar?

    private let titleUseCase: any RecentActionBucketItemsTitleUseCaseProtocol
    private let bucketItemsUseCase: any RecentActionBucketItemsUseCaseProtocol
    private let bucketItemsUpdateUseCase: any RecentActionBucketItemsUpdateUseCaseProtocol
    private var cancellables: Set<AnyCancellable> = []
    
    init(
        bucket: RecentActionBucketEntity,
        titleUseCase: some RecentActionBucketItemsTitleUseCaseProtocol = RecentActionBucketItemsTitleUseCase(),
        bucketItemsUpdateUseCase: some RecentActionBucketItemsUpdateUseCaseProtocol = RecentActionBucketItemsUpdateUseCase(),
        bucketItemsUseCase: some RecentActionBucketItemsUseCaseProtocol = RecentActionBucketItemsUseCase(),
    ) {
        self.bucket = bucket
        self.titleUseCase = titleUseCase
        self.bucketItemsUpdateUseCase = bucketItemsUpdateUseCase
        self.navigationTitle = titleUseCase.title(for: bucket, editingState: .inactive)
        self.photoLibraryContentViewModel = PhotoLibraryContentViewModel(
            library: bucket.photoLibrary,
            contentMode: .recentBucket,
            globalHeaderType: .none
        )
        self.bucketItemsUseCase = bucketItemsUseCase

        photoLibraryContentViewModel
            .selection
            .$photos
            .assign(to: &$selectedPhotos)
            
        $editMode
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] mode in
                guard let self else { return }
                photoLibraryContentViewModel.selection.editMode = mode
                if !mode.isEditing {
                    photoLibraryContentViewModel.selection.clear()
                }
            }
            .store(in: &cancellables)

        // Mirror long-press-driven edit-mode entry back to viewModel.editMode so the
        // navigation/toolbar (gated on viewModel.editMode) match the existing Select button.
        photoLibraryContentViewModel.selection.$editMode
            .dropFirst()
            .map(\.isEditing)
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self, !editMode.isEditing else { return }
                editMode = .active
            }
            .store(in: &cancellables)
        
        $selectedPhotos
            .map { $0.isEmpty }
            .assign(to: &$bottomBarDisabled)
        
        $bottomBarAction
            .compactMap { [weak self] action in
                guard let action, let self else { return nil }
                return action.toNodesAction(handles: Set(selectedPhotos.keys))
            }
            .assign(to: &$nodesAction)

        $nodesAction
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.exitEditMode()
            }
            .store(in: &cancellables)
        
        $selectedPhotos
            .combineLatest($editMode, $bucket)
            .map { [titleUseCase] nodes, editMode, bucket in
                titleUseCase.title(
                    for: bucket,
                    editingState: editMode.isEditing ? .active(selectedCount: nodes.count) : .inactive
                )
            }
            .assign(to: &$navigationTitle)

        $bucket
            .dropFirst()
            .sink { [weak self] updatedBucket in
                guard let self else { return }
                photoLibraryContentViewModel.library = updatedBucket.photoLibrary
                synchronizeSelection(with: updatedBucket)
            }
            .store(in: &cancellables)
    }

    func enterEditMode() {
        editMode = .active
    }

    func exitEditMode() {
        editMode = .inactive
    }

    func toggleSelectAll() {
        photoLibraryContentViewModel.toggleSelectAllPhotos()
    }

    func loadBucketItems() async {
        guard let updatedBucket = await bucketItemsUseCase.fetchBucketContent(forId: bucket.id) else {
            return setupSnackBarAndExit()
        }
        if updatedBucket.nodes.map(\.handle) != bucket.nodes.map(\.handle) {
            bucket = updatedBucket
        }
    }

    func monitorBucketUpdates() async {
        for await update in bucketItemsUpdateUseCase.bucketUpdates(forId: bucket.id) {
            guard !Task.isCancelled else { break }
            switch update {
            case .available(let updatedBucket):
                bucket = updatedBucket
            case .unavailable:
                setupSnackBarAndExit()
            }
            if isBucketEmpty { break } // once the bucket becomes empty, we don't need to observe updates anymore
        }
    }

    private func setupSnackBarAndExit() {
        fileNoLongerAvailableSnackBar = SnackBar(message: Strings.Localizable.Home.Recent.MixedFileBucket.Snackbar.filesNotAvailable)
        isBucketEmpty = true
    }

    private func synchronizeSelection(with updatedBucket: RecentActionBucketEntity) {
        let currentSelection = photoLibraryContentViewModel.selection.photos
        guard !currentSelection.isEmpty else { return }

        let updatedNodes = Dictionary(uniqueKeysWithValues: updatedBucket.nodes.map { ($0.handle, $0) })
        let validSelection = currentSelection.keys.compactMap { updatedNodes[$0] }

        if validSelection.count != currentSelection.count {
            photoLibraryContentViewModel.selection.setSelectedPhotos(validSelection)
        }
    }
}

extension RecentActionBucketItemsNavigationTitle {
    var displayableTitle: String {
        switch title {
        case let .all(count):
            Strings.Localizable.Recents.Section.Thumbnail.Count.image(count)
        case let .selected(count):
            Strings.Localizable.General.Format.itemsSelected(count)
        }
    }
    
    var displayableSubtitle: String? {
        switch subtitle {
        case let .addedBy(parentName, nodesCount):
            Strings.Localizable.Recents.BucketDetails.subtitle(nodesCount)
                .replacingOccurrences(of: "[A]", with: parentName)
        case .none:
            nil
        }
    }
}

extension RecentActionBucketEntity {
    var photoLibrary: PhotoLibrary {
        let photoByDay = PhotoByDay(categoryDate: date, contentList: nodes)
        let photoByMonth = PhotoByMonth(categoryDate: date, contentList: [photoByDay])
        let photoByYear = PhotoByYear(categoryDate: date, contentList: [photoByMonth])
        return PhotoLibrary(photoByYearList: [photoByYear])
    }
}
