

extension MEGAUser {
    @objc func fetchNickname(completionHandler: MEGAGenericRequestDelegate) {
        guard let sharedMEGASdk = MEGASdkManager.sharedMEGASdk() else {
            fatalError("shared MEGA SDK should not be nil")
        }
        
        sharedMEGASdk.getUserAlias(withHandle: handle, delegate: completionHandler)
    }
}
