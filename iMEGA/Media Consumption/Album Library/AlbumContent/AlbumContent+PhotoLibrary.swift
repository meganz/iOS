import Foundation

@available(iOS 14.0, *)
extension AlbumContentViewController: PhotoLibraryProvider {
    func enableNavigationEditBarButton(_ enable: Bool) {
        rightBarButtonItem.isEnabled = false
    }
    
    func showNavigationRightBarButton(_ show: Bool) {
        navigationItem.rightBarButtonItem = show ? rightBarButtonItem : nil
    }
}
