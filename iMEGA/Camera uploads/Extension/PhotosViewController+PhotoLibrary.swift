import ContentLibraries
import Foundation
import MEGAL10n
import SwiftUI

private var AssociatedPhotoLibraryContentViewModelHandle: UInt8 = 0

extension PhotosViewController: PhotoLibraryProvider {
    public var photoLibraryContentViewModel: PhotoLibraryContentViewModel {
        get {
            guard let viewModel = objc_getAssociatedObject(self, &AssociatedPhotoLibraryContentViewModelHandle) as? PhotoLibraryContentViewModel else {
                let viewModel = createPhotoLibraryContentViewModel()
                self.photoLibraryContentViewModel = viewModel
                return viewModel
            }
            return viewModel
        }
        set {
            objc_setAssociatedObject(self, &AssociatedPhotoLibraryContentViewModelHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - config views
    @objc func objcWrapper_configPhotoLibraryView(in container: UIView) {
        let content = TimelineView(
            photoLibraryContentViewModel: photoLibraryContentViewModel,
            timelineViewModel: viewModel.timelineViewModel,
            router: PhotoLibraryContentViewRouter(contentMode: photoLibraryContentViewModel.contentMode),
            onFilterUpdate: { [weak self] type, location in
                self?.viewModel.updateFilter(filterType: type, filterLocation: location)
                self?.setupNavigationBarButtons()
            })
        
        let host = UIHostingController(rootView: content)
        addChild(host)
        container.wrap(host.view)
        host.view.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        host.didMove(toParent: self)
    }
    
    @objc func objcWrapper_updatePhotoLibrary() {
        updatePhotoLibrary(
            by: viewModel.mediaNodes,
            withSortType: viewModel.cameraUploadExplorerSortOrderType.toSortOrderEntity(),
            in: UIHostingController<TimelineView>.self,
            hideHostOnEmpty: false
        )
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
    
    public func hideNavigationEditBarButton(_ hide: Bool) { }
    
    // MARK: - override
    
    public func updateNavigationTitle(withSelectedPhotoCount count: Int) {
        var message = ""
        
        if count == 0 {
            message = Strings.Localizable.selectTitle
        } else {
            message = Strings.Localizable.General.Format.itemsSelected(count)
        }
        
        objcWrapper_parent.navigationItem.title = message
    }
}
