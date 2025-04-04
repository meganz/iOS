import MEGAAppSDKRepo

extension MEGASdk {
    
    @objc static let shared: MEGASdk = {
        MEGASdk.sharedSdk
    }()
    
    static let sharedNSE: MEGASdk = {
        MEGASdk.sharedNSESdk
    }()
    
    @objc static let sharedFolderLink: MEGASdk = {
        MEGASdk.sharedFolderLinkSdk
    }()
}
