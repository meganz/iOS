
extension MEGANode {
    private func isBackupChildNode() -> Bool {
        var currentNode: MEGANode? = self
        while let node = currentNode, let parent = MEGASdkManager.sharedMEGASdk().parentNode(for: node) {
            if BackupRootNodeAccess.shared.isTargetNode(for: parent) && node.deviceId?.isEmpty == false {
                return true
            }
            currentNode = MEGASdkManager.sharedMEGASdk().parentNode(for: node)
        }
        return false
    }
    
    @objc func isBackupNode() -> Bool {
        deviceId?.isEmpty == false || isBackupChildNode()
    }
    
    @objc func isBackupRootNode() -> Bool {
        BackupRootNodeAccess.shared.isTargetNode(for: self)
    }
    
    @objc func numberOfDevices(sdk: MEGASdk) -> String? {
        guard isBackupRootNode() else { return nil }
        let devices = sdk.children(forParent: self).nodes.filter{$0.isBackupNode()}.count
        
        if devices > 1 {
            return Strings.Localizable.CloudDrive.Root.Backup.Folder.Devices.subtitle(devices)
        } else if devices > 0 {
            return Strings.Localizable.CloudDrive.Root.Backup.Folder.Device.subtitle(devices)
        }
        return Strings.Localizable.General.emptyFolder
    }
}
