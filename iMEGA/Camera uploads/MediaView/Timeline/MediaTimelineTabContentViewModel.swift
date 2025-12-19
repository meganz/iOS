import Combine
import MEGADomain
import SwiftUI

@MainActor
final class MediaTimelineTabContentViewModel: ObservableObject, MediaTabContentViewModel, MediaTabSharedResourceConsumer {
    weak var sharedResourceProvider: (any MediaTabSharedResourceProvider)?
    let editModeToggleRequested = PassthroughSubject<Void, Never>()
   
    let timelineViewModel: NewTimelineViewModel
    
    init(timelineViewModel: NewTimelineViewModel) {
        self.timelineViewModel = timelineViewModel
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
            items.append(MediaNavigationBarItemFactory.cancelButton(action: toggleEditMode))
        } else {
            if let cameraUploadStatusButtonViewModel = sharedResourceProvider?.cameraUploadStatusButtonViewModel {
                items.append(MediaNavigationBarItemFactory.cameraUploadStatusButton(
                    viewModel: cameraUploadStatusButtonViewModel
                ))
            }
            items.append(MediaNavigationBarItemFactory.searchButton {
                
            })
            if let config = sharedResourceProvider?.contextMenuConfig,
               let manager = sharedResourceProvider?.contextMenuManager {
                items.append(MediaNavigationBarItemFactory.contextMenuButton(
                    config: config, manager: manager))
            }
        }
        
        return items
    }
    
    private func toggleEditMode() {
        timelineViewModel.photoLibraryContentViewModel.toggleEditMode()
        editModeToggleRequested.send()
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

extension MediaTimelineTabContentViewModel: MediaTabContextMenuActionHandler {
    func handleDisplayAction(_ action: DisplayActionEntity) {
        if action == .select {
            toggleEditMode()
        }
    }
    
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
