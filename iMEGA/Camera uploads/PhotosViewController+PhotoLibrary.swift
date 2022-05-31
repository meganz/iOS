import Foundation
import SwiftUI

@available(iOS 14.0, *)
extension PhotosViewController: PhotoLibraryProvider {
    // MARK: - config views
    @objc func objcWrapper_configPhotoLibraryView(in container: UIView) {
        configPhotoLibraryView(in: container)
    }
    
    @objc func objcWrapper_updatePhotoLibrary(by nodes: [MEGANode]) {
        updatePhotoLibrary(by: nodes)
    }
    
    @objc func createPhotoLibraryContentViewModel() -> PhotoLibraryContentViewModel {
        PhotoLibraryContentViewModel(library: PhotoLibrary())
    }
    
    @objc func objcWrapper_updateNavigationTitle(withSelectedPhotoCount count: Int) {
        updateNavigationTitle(withSelectedPhotoCount: count)
    }
    
    @objc func objcWrapper_configPhotoLibrarySelectAll() {
        configPhotoLibrarySelectAll()
    }
    
    @objc func objcWrapper_enablePhotoLibraryEditMode(_ enable: Bool) {
        parentPhotoAlbumsController?.isEditing = enable
        enablePhotoLibraryEditMode(enable)
    }
    
    func hideNavigationEditBarButton(_ hide: Bool) {
        objcWrapper_parent.navigationItem.rightBarButtonItem = hide ? nil : editBarButtonItem
    }
    
    // Mark: - override
    
    func updateNavigationTitle(withSelectedPhotoCount count: Int) {
        var message = ""
        
        if count == 0 {
            message = Strings.Localizable.selectTitle
        } else if count == 1 {
            message = Strings.Localizable.oneItemSelected(count)
        } else {
            message = Strings.Localizable.itemsSelected(count)
        }
        
        objcWrapper_parent.navigationItem.title = message
    }
}
