import Foundation

@available(iOS 14.0, *)
extension CloudDriveViewController {
    @objc func shouldShowMediaDiscovery() -> Bool {
        guard let parent = parentNode else { return false }
        
        return parent.type != .root && hasMediaFiles && !isFromSharedItem
    }
    
    @objc func mediaDiscoveryAction() -> ActionSheetAction? {
        guard shouldShowMediaDiscovery(), let parent = parentNode else { return nil }
        
        let title = Strings.Localizable.CloudDrive.Menu.MediaDiscovery.title
        let image = Asset.Images.ActionSheetIcons.mediaDiscovery.image
        let action = ActionSheetAction(title: title, detail: nil, image: image, style: .default) {
            MediaDiscoveryRouter(viewController: self, parentNode: parent).start()
        }
        
        return action
    }
}
