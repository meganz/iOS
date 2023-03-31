import Foundation

extension MediaDiscoveryViewController: PhotoLibraryProvider {
    func showNavigationRightBarButton(_ show: Bool) {
        navigationItem.rightBarButtonItem = show ? rightBarButtonItem : nil
    }
        
    func didSelectedPhotoCountChange(_ count: Int) {
        updateNavigationTitle(withSelectedPhotoCount: count)
        configureToolbarButtons()
    }
    
    func setupPhotoLibrarySubscriptions() {
        photoLibraryPublisher.subscribeToSelectedModeChange { [weak self] in
            self?.showNavigationRightBarButton($0 == .all)
        }
        
        photoLibraryPublisher.subscribeToSelectedPhotosChange { [weak self] in
            self?.selection.setSelectedNodes(Array($0.values))
            self?.didSelectedPhotoCountChange($0.count)
        }
        
        photoLibraryPublisher.subscribeToPhotoSelectionHidden { [weak self] in
            self?.hideNavigationEditBarButton($0)
        }
    }
    
    func hideNavigationEditBarButton(_ hide: Bool) {
        navigationItem.rightBarButtonItem = hide ? nil : rightBarButtonItem
    }
}
