import UIKit

extension PhotosViewController {
    private func isMediaNotFoundEmptyState(filterType: PhotosFilterOptions, filterLocation: PhotosFilterOptions) -> Bool {
        filterType == .allMedia && (filterLocation == .allLocations || filterLocation == .cloudDrive || filterLocation == .cameraUploads)
    }
    
    private func isImageNotFoundEmptyState(filterType: PhotosFilterOptions, filterLocation: PhotosFilterOptions) -> Bool {
        filterType == .images && (filterLocation == .allLocations || filterLocation == .cloudDrive || filterLocation == .cameraUploads)
    }
    
    private func isVideoNotFoundEmptyState(filterType: PhotosFilterOptions, filterLocation: PhotosFilterOptions) -> Bool {
        filterType == .videos && (filterLocation == .allLocations || filterLocation == .cloudDrive || filterLocation == .cameraUploads)
    }
    
    private func isEmptyStateView(filterType: PhotosFilterOptions, filterLocation: PhotosFilterOptions) -> Bool {
        isMediaNotFoundEmptyState(filterType: filterType, filterLocation: filterLocation) ||
        (filterType == .allMedia && filterLocation == .cameraUploads) ||
        (filterType == .images && filterLocation == .allLocations) ||
        (filterType == .images && filterLocation == .cameraUploads) ||
        (filterType == .videos && filterLocation == .allLocations) ||
        (filterType == .videos && filterLocation == .cameraUploads)
    }
    
    @objc func emptyStateView(withImage image: UIImage? = nil,
                              title: String? = nil,
                              description: String? = nil,
                              buttonTitle: String? = nil) -> EmptyStateView {
        
        var emptyView: EmptyStateView = EmptyStateView.create(for: .timeline(image: image, title: title, description: description, buttonTitle: buttonTitle))
        let filterType = viewModel.filterType
        let filterLocation = viewModel.filterLocation
                
        if CameraUploadManager.isCameraUploadEnabled {
            if isImageNotFoundEmptyState(filterType: filterType, filterLocation: filterLocation) {
                emptyView = EmptyStateView.create(for: EmptyStateType.photos)
            } else if isVideoNotFoundEmptyState(filterType: filterType, filterLocation: filterLocation) {
                emptyView = EmptyStateView.create(for: EmptyStateType.videos)
            } else if isMediaNotFoundEmptyState(filterType: filterType, filterLocation: filterLocation) {
                emptyView = EmptyStateView.create(for: EmptyStateType.allMedia)
            }
        } else {
            if filterType == .allMedia && filterLocation == .cloudDrive {
                emptyView = EmptyStateView.create(for: EmptyStateType.allMedia)
            } else if filterType == .images && filterLocation == .cloudDrive {
                emptyView = EmptyStateView.create(for: EmptyStateType.photos)
            } else if filterType == .videos && filterLocation == .cloudDrive {
                emptyView = EmptyStateView.create(for: EmptyStateType.videos)
            } else if isEmptyStateView(filterType: filterType, filterLocation: filterLocation) {
                emptyView = EmptyStateView.create(for: .timeline(image: image, title: title, description: description, buttonTitle: buttonTitle))
                emptyView.button?.addTarget(self, action: #selector(buttonTouchUpInsideEmptyState), for: .touchUpInside)
            } 
        }
        return emptyView
    }
}
