import Foundation
import SwiftUI

@available(iOS 14.0, *)
extension PhotosViewController {
    // MARK: - config views
    @objc func configPhotoLibraryView(in container: UIView) {
        let content = PhotoLibraryContentView(
            viewModel: photoLibraryContentViewModel,
            router: PhotoLibraryContentViewRouter()
        )
        
        let host = UIHostingController(rootView: content)
        addChild(host)
        container.wrap(host.view)
        host.view.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        host.didMove(toParent: self)
    }
    
    @objc func updatePhotoLibrary(by nodes: [MEGANode]) {
        guard let libraryChild = children.first(where: { $0 is UIHostingController<PhotoLibraryContentView> }),
              let host = libraryChild as? UIHostingController<PhotoLibraryContentView> else {
                  return
              }
        
        DispatchQueue.global(qos: .userInitiated).async {
            MEGALogDebug("[Photos] update photo library")
            let photoLibrary: PhotoLibrary = nodes.toPhotoLibrary()
            
            DispatchQueue.main.async {
                host.view.isHidden = photoLibrary.isEmpty
                self.photoLibraryContentViewModel.library = photoLibrary
            }
        }
    }
    
    @objc func createPhotoLibraryContentViewModel() -> PhotoLibraryContentViewModel {
        PhotoLibraryContentViewModel(library: PhotoLibrary())
    }
    
    @objc func updateNavigationTitle(withPhotoCount count: Int) {
        var message = ""
        
        if count == 0 {
            message = Strings.Localizable.selectTitle
        } else if count == 1 {
            message = Strings.Localizable.oneItemSelected(count)
        } else {
            message = Strings.Localizable.itemsSelected(count)
        }
        
        navigationItem.title = message
    }
    
    @objc func selectAllPhotoLibrary(_ shouldSelectAll: Bool) {
        if shouldSelectAll {
            photoLibraryContentViewModel.selection.selectAll(photos: photoLibraryContentViewModel.library.allPhotos)
        } else {
            photoLibraryContentViewModel.selection.unselectAll()
        }
    }
    
    @objc func enablePhotoLibraryEditMode(_ enable: Bool) {
        photoLibraryContentViewModel.selection.editMode = enable ? .active : .inactive
    }
}
