
extension MEGAUser {
    func avatarImage(withDelegate delegate: MEGARequestDelegate?) -> UIImage? {
        guard let base64Handle = MEGASdk.base64Handle(forHandle: handle) else { return nil }
        
        let filePath = Helper
            .path(forSharedSandboxCacheDirectory: "thumbnailsV3")
            .append(pathComponent: base64Handle)
        
        if FileManager.default.fileExists(atPath: filePath) {
            return UIImage(contentsOfFile: filePath)
        } else {
            if let `delegate` = delegate {
                MEGASdkManager.sharedMEGASdk().getAvatarUser(self,
                                                             destinationFilePath: filePath,
                                                             delegate: delegate)
            } else {
                MEGASdkManager.sharedMEGASdk().getAvatarUser(self, destinationFilePath: filePath)
            }
        }
        
        return nil
    }
}
