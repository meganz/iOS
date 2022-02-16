import SwiftUI

@available(iOS 14.0, *)
extension PhotosExplorerViewController {
    
    func configPhotoLibraryView(in container: UIView) {
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
    
    func updateImageLibrary(by nodes: [MEGANode]) {
        guard let libraryChild = children.first(where: { $0 is UIHostingController<PhotoLibraryContentView> }),
              let host = libraryChild as? UIHostingController<PhotoLibraryContentView> else {
                  return
              }
        
        DispatchQueue.global(qos: .userInitiated).async {
            MEGALogDebug("[Image] update Image library")
            let photoLibrary: PhotoLibrary = nodes.toPhotoLibrary()
            
            DispatchQueue.main.async { [weak self] in
                host.view.isHidden = photoLibrary.isEmpty
                self?.photoLibraryContentViewModel.library = photoLibrary
            }
        }
    }
    
    func enablePhotoLibraryEditMode(_ enable: Bool) {
        photoLibraryContentViewModel.selection.editMode = enable ? .active : .inactive
    }
    
    func showNavigationRightBarButton(_ show: Bool) {
        navigationItem.rightBarButtonItem = show ? editBarButtonItem : nil
    }
    
    func updateNavigationTitle(withPhotoCount count: Int) {
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
    
    func didSelectedPhotoCountChange(_ count: Int) {
        updateNavigationTitle(withPhotoCount: count)
        configureToolbarButtons()
    }
    
    func selectAllPhotoLibrary() {
        photoLibraryContentViewModel.selection.allSelected = photoLibraryContentViewModel.selection.photos.count ==
                                                             photoLibraryContentViewModel.library.allPhotos.count
        
        photoLibraryContentViewModel.selection.allSelected.toggle()
        
        if photoLibraryContentViewModel.selection.allSelected {
            photoLibraryContentViewModel.selection.selectAll(photos: photoLibraryContentViewModel.library.allPhotos)
        } else {
            photoLibraryContentViewModel.selection.unselectAll()
        }
    }
}
