import MEGADomain
import MEGAL10n

/// Used by MediaContentDiscoveryView to send back information regarding selection state and empty state
/// We allocate it in the CloudDriveViewControllerFactory , object is retained by NodeBrowserViewModel.actionHandlers
final class MediaContentDelegateHandler: MediaDiscoveryContentDelegate {
    
    var isMediaDiscoverySelectionHandler: ((_ isHidden: Bool) -> Void)?
    var selectedPhotosHandler: ((_ selected: [NodeEntity], _ allPhotos: [NodeEntity]) -> Void)?
    var mediaDiscoverEmptyTappedHandler: ((EmptyMediaDiscoveryContentMenuAction) -> Void)?
    
    func selectedPhotos(selected: [NodeEntity], allPhotos: [NodeEntity]) {
        selectedPhotosHandler?(selected, allPhotos)
    }
    
    func isMediaDiscoverySelection(isHidden: Bool) {
        isMediaDiscoverySelectionHandler?(isHidden)
    }
    
    func mediaDiscoverEmptyTapped(menuAction: EmptyMediaDiscoveryContentMenuAction) {
        mediaDiscoverEmptyTappedHandler?(menuAction)
    }
}
