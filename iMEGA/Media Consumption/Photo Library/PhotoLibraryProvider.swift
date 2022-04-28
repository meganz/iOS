import Foundation
import SwiftUI

@available(iOS 14.0, *)
protocol PhotoLibraryProvider: UIViewController {
    var photoLibraryContentViewModel: PhotoLibraryContentViewModel { get }
    
    func configPhotoLibraryView(in container: UIView)
    func updatePhotoLibrary(by nodes: [MEGANode])
    func enablePhotoLibraryEditMode(_ enable: Bool)
    func configPhotoLibrarySelectAll()
    func updateNavigationTitle(withSelectedPhotoCount count: Int)
}

@available(iOS 14.0, *)
@MainActor
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
    
    func updatePhotoLibrary(by nodes: [MEGANode]) {
        guard let host = children.first(where: { $0 is UIHostingController<PhotoLibraryContentView> }) else {
            return
        }
        
        Task {
            let photoLibrary = await load(by: nodes)
            
            host.view.isHidden = photoLibrary.isEmpty
            photoLibraryContentViewModel.library = photoLibrary
        }
    }
    
    func enablePhotoLibraryEditMode(_ enable: Bool) {
        photoLibraryContentViewModel.selection.editMode = enable ? .active : .inactive
    }
    
    func configPhotoLibrarySelectAll() {
        photoLibraryContentViewModel.selection.allSelected = photoLibraryContentViewModel.selection.photos.count ==
        photoLibraryContentViewModel.library.allPhotos.count
        
        photoLibraryContentViewModel.selection.allSelected.toggle()
        
        if photoLibraryContentViewModel.selection.allSelected {
            photoLibraryContentViewModel.selection.selectAll(photos: photoLibraryContentViewModel.library.allPhotos)
        } else {
            photoLibraryContentViewModel.selection.unselectAll()
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
    
    // MARK: - Private
    
    private func load(by nodes: [MEGANode]) async -> PhotoLibrary {
        let trasferMapper = PhotoLibraryMapper()
        let lib = await trasferMapper.buildPhotoLibrary(with: nodes)
        
        return lib
    }
}
