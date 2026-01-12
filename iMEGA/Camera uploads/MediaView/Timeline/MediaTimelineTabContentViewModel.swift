import Combine
import MEGADomain
import SwiftUI

@MainActor
final class MediaTimelineTabContentViewModel: ObservableObject, MediaTabContentViewModel, MediaTabSharedResourceConsumer {
    weak var sharedResourceProvider: (any MediaTabSharedResourceProvider)? {
        didSet {
            setupEditModeSubscription()
        }
    }
    let editModeToggleRequested = PassthroughSubject<Void, Never>()
    weak var toolbarCoordinator: (any MediaTabToolbarCoordinatorProtocol)?
   
    let timelineViewModel: NewTimelineViewModel

    private var subscriptions = Set<AnyCancellable>()
    
    init(timelineViewModel: NewTimelineViewModel) {
        self.timelineViewModel = timelineViewModel
        setupEditModeSubscription()
    }
    
    private func setupEditModeSubscription() {
        guard let sharedResourceProvider else { return }

        sharedResourceProvider.editModePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.timelineViewModel.updateEditMode($0)
            }
            .store(in: &subscriptions)
    }
}

extension MediaTimelineTabContentViewModel: MediaTabNavigationBarItemProvider {
    var navigationBarUpdatePublisher: AnyPublisher<Void, Never>? {
        timelineViewModel.photoLibraryContentViewModel.$library
            .map(\.isEmpty)
            .removeDuplicates()
            .dropFirst()
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    func navigationBarItems(for editMode: EditMode) -> [NavigationBarItemViewModel] {
        var items: [NavigationBarItemViewModel] = []
        
        if editMode == .active {
            items.append(MediaNavigationBarItemFactory.cancelButton(
                action: editModeToggleRequested.send))
        } else {
            if let cameraUploadStatusButtonViewModel = sharedResourceProvider?.cameraUploadStatusButtonViewModel {
                items.append(MediaNavigationBarItemFactory.cameraUploadStatusButton(
                    viewModel: cameraUploadStatusButtonViewModel
                ))
            }
            items.append(MediaNavigationBarItemFactory.searchButton { [weak self] in
                self?.sharedResourceProvider?.toggleSearch()
            })
            if let config = sharedResourceProvider?.contextMenuConfig,
               let manager = sharedResourceProvider?.contextMenuManager {
                items.append(MediaNavigationBarItemFactory.contextMenuButton(
                    config: config, manager: manager))
            }
        }
        
        return items
    }
}

// MARK: - MediaTabContextMenuProvider

extension MediaTimelineTabContentViewModel: MediaTabContextMenuProvider {
    func contextMenuConfiguration() -> CMConfigEntity? {
        CMConfigEntity(
            menuType: .menu(type: .mediaTabTimeline),
            sortType: timelineViewModel.sortOrder,
            isCameraUploadExplorer: true,
            isEmptyState: timelineViewModel.photoLibraryContentViewModel.isPhotoLibraryEmpty,
            isCameraUploadsEnabled: timelineViewModel.isCameraUploadsEnabled,
            selectedPhotoFilter: timelineViewModel.photoFilterOptions
        )
    }
}

extension MediaTimelineTabContentViewModel: NodeActionDisplayModeProvider {
    var displayMode: DisplayMode {
        .photosTimeline
    }
}

extension MediaTimelineTabContentViewModel: MediaTabContextMenuActionHandler {
    func handleQuickAction(_ action: QuickActionEntity) {
        if action == .settings {
            Task { @MainActor [weak timelineViewModel] in
                // Allow context menu dismissal to complete
                await Task.yield()
                timelineViewModel?.navigateToCameraUploadSettings()
            }
        }
    }
    
    func handleSortAction(_ sortType: SortOrderType) {
        timelineViewModel.updateSortOrder(sortType.toSortOrderEntity())
    }
    
    func handlePhotoFilter(option: PhotosFilterOptionsEntity) {
        timelineViewModel.updatePhotoFilter(option: option)
    }
}

extension MediaTimelineTabContentViewModel: MediaTabToolbarActionsProvider {
    var toolbarUpdatePublisher: AnyPublisher<Void, Never>? {
        timelineViewModel.photoLibraryContentViewModel.selection.$photos
            .dropFirst()
            .map { $0.isEmpty }
            .removeDuplicates()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func toolbarConfig() -> MediaBottomToolbarConfig? {
        let selectedNodes = selectedNodesForToolbar
        let selectedCount = selectedNodes.count

        let actions: [MediaBottomToolbarAction] = [
            .download, .manageLink, .addToAlbum, .moveToRubbishBin, .more]

        return MediaBottomToolbarConfig(
            actions: actions,
            selectedItemsCount: selectedCount
        )
    }

    /// Private helper to get selected nodes for internal use
    private var selectedNodesForToolbar: [NodeEntity] {
        Array(timelineViewModel.photoLibraryContentViewModel.selectedPhotos)
    }
}

// MARK: - MediaTabToolbarActionHandler

extension MediaTimelineTabContentViewModel: MediaTabToolbarActionHandler {
    func handleToolbarAction(_ action: MediaBottomToolbarAction) {
        let nodes = selectedNodesForToolbar
        guard !nodes.isEmpty else { return }

        toolbarCoordinator?.handleToolbarAction(action, with: nodes)
    }
}
