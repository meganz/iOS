import Foundation
import MEGADomain
import MEGAL10n
import SwiftUI
import UIKit

@MainActor
public protocol PhotoLibraryProvider: UIViewController {
    var photoLibraryContentViewModel: PhotoLibraryContentViewModel { get }
    
    func configPhotoLibraryView(in container: UIView, router: some PhotoLibraryContentViewRouting, onFilterUpdate: ((PhotosFilterOptions, PhotosFilterOptions) -> Void)?)
    func updatePhotoLibrary(by nodes: [NodeEntity], withSortType type: SortOrderEntity,
                            in hostControllerType: UIViewController.Type, hideHostOnEmpty: Bool)
    func hideNavigationEditBarButton(_ hide: Bool)
    func enablePhotoLibraryEditMode(_ enable: Bool)
    func configPhotoLibrarySelectAll()
    func updateNavigationTitle(withSelectedPhotoCount count: Int)
    func disablePhotoSelection(_ disable: Bool)
}

public extension PhotoLibraryProvider {
    func configPhotoLibraryView(
        in container: UIView,
        router: some PhotoLibraryContentViewRouting,
        onFilterUpdate: ((PhotosFilterOptions, PhotosFilterOptions) -> Void)? = nil) {
        let content = PhotoLibraryContentView(
            viewModel: photoLibraryContentViewModel,
            router: router,
            onFilterUpdate: onFilterUpdate
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
        photoLibraryContentViewModel.toggleSelectAllPhotos()
    }
    
    func updateNavigationTitle(withSelectedPhotoCount count: Int) {
        var message = ""
        
        if count == 0 {
            message = Strings.Localizable.selectTitle
        } else {
            message = Strings.Localizable.General.Format.itemsSelected(count)
        }
        
        navigationItem.title = message
    }
    
    func updatePhotoLibrary(
        by nodes: [NodeEntity],
        withSortType type: SortOrderEntity = .modificationDesc,
        in hostControllerType: UIViewController.Type = UIHostingController<PhotoLibraryContentView>.self,
        hideHostOnEmpty: Bool = true
    ) {
        
        guard let host = children.first(where: { Swift.type(of: $0) === hostControllerType }) else {
            return
        }
        
        Task {
            let photoLibrary = await load(by: nodes, withSortType: type)
            
            host.view.isHidden = hideHostOnEmpty && photoLibrary.isEmpty
            photoLibraryContentViewModel.library = photoLibrary
            
            hideNavigationEditBarButton(photoLibrary.isEmpty)
        }
    }
    
    func disablePhotoSelection(_ disable: Bool) {
        photoLibraryContentViewModel.selection.isSelectionDisabled = disable
    }
    
    // MARK: - Private
    
    private func load(by nodes: [NodeEntity], withSortType type: SortOrderEntity) async -> PhotoLibrary {
        let mapper = PhotoLibraryMapper()
        let lib = await mapper.buildPhotoLibrary(with: nodes, withSortType: type)
        
        return lib
    }
}
