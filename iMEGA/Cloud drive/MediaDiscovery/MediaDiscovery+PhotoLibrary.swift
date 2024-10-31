import ContentLibraries
import Foundation

extension MediaDiscoveryViewController: PhotoLibraryProvider {
    func didSelectedPhotoCountChange(_ count: Int) {
        updateNavigationTitle(withSelectedPhotoCount: count)
        configureToolbarButtons()
    }
    
    func setupPhotoLibrarySubscriptions() {
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
