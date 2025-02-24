// DO NOT USE DIRECTLY, only use via CloudDriveViewControllerFactory
struct LegacyCloudDriveViewControllerFactory {
    func build(
        nodeSource: NodeSource,
        config: NodeBrowserConfig,
        sdk: MEGASdk
    ) -> UIViewController? {
        let storyboard = UIStoryboard(name: "Cloud", bundle: nil)
        guard let vc =
                storyboard.instantiateViewController(withIdentifier: "CloudDriveID") as? CloudDriveViewController
        else { return nil }
        
        switch nodeSource {
        case .node(let nodeProvider):
            if
                let nodeEntity = nodeProvider(),
                let megaNode = sdk.node(forHandle: nodeEntity.handle)
            {
                vc.parentNode = megaNode
            }
        case .recentActionBucket(let bucket):
            // we should crash here since it's not possible to proceed if casting fails
            // bucket property on the MEGARecentActionBucketTrampoline can be removed when
            // this file is removed
            vc.recentActionBucket = (bucket as! MEGARecentActionBucketTrampoline).bucket
        }
        
        if let displayMode = config.displayMode {
            vc.displayMode = displayMode
        }
        if let isFromViewInFolder = config.isFromViewInFolder {
            vc.isFromViewInFolder = isFromViewInFolder
        }
        
        if let isFromUnverifiedContactSharedFolder = config.isFromUnverifiedContactSharedFolder {
            vc.isFromUnverifiedContactSharedFolder = isFromUnverifiedContactSharedFolder
        }
        
        if let isFromSharedItem = config.isFromSharedItem {
            vc.isFromSharedItem = isFromSharedItem
        }
        
        if let shouldRemovePlayerDelegate = config.shouldRemovePlayerDelegate {
            vc.shouldRemovePlayerDelegate = shouldRemovePlayerDelegate
        }
        
        if let warningViewModel = config.warningViewModel {
            vc.warningViewModel = warningViewModel
        }
        
        return vc
    }
}
