import Foundation
import SwiftUI

@available(iOS 14.0, *)
@MainActor
protocol PhotoLibraryProvider: UIViewController {
    var photoLibraryContentViewModel: PhotoLibraryContentViewModel { get }
    
    func configPhotoLibraryView(in container: UIView)
    func updatePhotoLibrary<T: PhotoLibraryNodeProtocol>(by nodes: [T])
    func hideNavigationEditBarButton(_ hide: Bool)
    func enablePhotoLibraryEditMode(_ enable: Bool)
    func configPhotoLibrarySelectAll()
    func updateNavigationTitle(withSelectedPhotoCount count: Int)
}

@available(iOS 14.0, *)
extension PhotoLibraryProvider {
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
    
    func enablePhotoLibraryEditMode(_ enable: Bool) {
        photoLibraryContentViewModel.selection.editMode = enable ? .active : .inactive
    }
    
    func configPhotoLibrarySelectAll() {
        let allSelectedCurrently = photoLibraryContentViewModel.selection.photos.count == photoLibraryContentViewModel.library.allPhotos.count
        photoLibraryContentViewModel.selection.allSelected = !allSelectedCurrently
        
        if photoLibraryContentViewModel.selection.allSelected {
            photoLibraryContentViewModel.selection.setSelectedPhotos(photoLibraryContentViewModel.library.allPhotos)
        }
    }
    
    func updateNavigationTitle(withSelectedPhotoCount count: Int) {
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
    
    func updatePhotoLibrary<T:PhotoLibraryNodeProtocol>(by nodes: [T]) {
        guard let host = children.first(where: { $0 is UIHostingController<PhotoLibraryContentView> }) else {
            return
        }
        
        Task {
            let photoLibrary = await load(by: nodes)
            
            host.view.isHidden = photoLibrary.isEmpty
            photoLibraryContentViewModel.library = photoLibrary
            
            hideNavigationEditBarButton(photoLibrary.isEmpty)
        }
    }
    
    // MARK: - Private
    
    private func load(by nodes: [PhotoLibraryNodeProtocol]) async -> PhotoLibrary {
        let mapper = PhotoLibraryMapper()
        let lib = await mapper.buildPhotoLibrary(with: nodes)
        
        return lib
    }
}
