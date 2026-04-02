import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
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
    
    private let titleUseCase: any RecentActionBucketItemsTitleUseCaseProtocol
    private let bucketItemsUpdateUseCase: any RecentActionBucketItemsUpdateUseCaseProtocol
    private var cancellables: Set<AnyCancellable> = []
    
    init(
        bucket: RecentActionBucketEntity,
        titleUseCase: some RecentActionBucketItemsTitleUseCaseProtocol = RecentActionBucketItemsTitleUseCase(),
        bucketItemsUpdateUseCase: some RecentActionBucketItemsUpdateUseCaseProtocol = RecentActionBucketItemsUpdateUseCase()
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
            .map {
                $0.photoLibrary
            }
            .assign(to: &photoLibraryContentViewModel.$library)
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

    func monitorBucketUpdates() async {
        for await updatedBucket in bucketItemsUpdateUseCase.bucketUpdates(forId: bucket.id) {
            guard !Task.isCancelled else { break }
            bucket = updatedBucket
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
        case let .addedBy(parentName):
            Strings.Localizable.Home.Recent.addedToLabel(parentName)
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
