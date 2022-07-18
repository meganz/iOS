import UIKit

extension PhotosViewController {
    
    @objc func emptyStateView(withImage image: UIImage? = nil,
                              title: String? = nil,
                              description: String? = nil,
                              buttonTitle: String? = nil) -> EmptyStateView {
        let emptyView: EmptyStateView
        
        if !CameraUploadManager.isCameraUploadEnabled {
            emptyView = EmptyStateView.create(for: .timeline, image: image, title: title, description: description, buttonTitle: buttonTitle)
            emptyView.button?.addTarget(self, action: #selector(buttonTouchUpInsideEmptyState), for: .touchUpInside)
        } else {
            var stateType = EmptyStateType.timeline
            
            if viewModel.filterType == PhotosFilterOptions.images {
                stateType = EmptyStateType.photos
            } else if viewModel.filterType == PhotosFilterOptions.videos {
                stateType = EmptyStateType.videos
            } else {
                stateType = EmptyStateType.allMedia
            }
            
            emptyView = EmptyStateView.create(for: stateType)
        }
        
        return emptyView
    }
}
