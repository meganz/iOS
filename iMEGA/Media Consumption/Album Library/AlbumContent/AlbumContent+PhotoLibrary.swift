import ContentLibraries
import Foundation
import MEGADomain

extension AlbumContentViewController: PhotoLibraryProvider {
    
    func hideNavigationEditBarButton(_ hide: Bool) {
        
    }
    
    func setupPhotoLibrarySubscriptions() {
        photoLibraryPublisher.subscribeToSelectedPhotosChange { [weak self] in
            self?.selection.setSelectedNodes(Array($0.values))
            self?.didSelectedPhotoCountChange($0.count)
        }
        
        photoLibraryPublisher.subscribeToPhotoSelectionHidden { [weak self] in
            self?.viewModel.dispatch(.configureContextMenu(isSelectHidden: $0))
        }
    }
    
    func didSelectedPhotoCountChange(_ count: Int) {
        updateNavigationTitle(withSelectedPhotoCount: count)
        configureToolbarButtonsWithAlbumType()
    }
}
