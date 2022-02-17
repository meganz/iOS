import SwiftUI

@available(iOS 14.0, *)
extension PhotosExplorerViewController: PhotoLibraryProvider {
    func showNavigationRightBarButton(_ show: Bool) {
        navigationItem.rightBarButtonItem = show ? editBarButtonItem : nil
    }
        
    func didSelectedPhotoCountChange(_ count: Int) {
        updateNavigationTitle(withSelectedPhotoCount: count)
        configureToolbarButtons()
    }
}
