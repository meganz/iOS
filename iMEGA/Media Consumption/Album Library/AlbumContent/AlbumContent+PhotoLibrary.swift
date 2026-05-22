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
        
        photoLibraryPublisher.subscribeToEditModeChange { [weak self] editMode in
            guard let self, editMode.isEditing, !isEditing else { return }
            startEditingMode()
        }
    }
    
    func didSelectedPhotoCountChange(_ count: Int) {
        updateNavigationTitle(selectedPhotoCount: count)
        configureToolbarButtonsWithAlbumType()
    }
}
