
extension MEGANode {
    @objc func isBackupNode() -> Bool {
        deviceId?.isEmpty == false
    }
    
    @objc func isBackupRootNode() -> Bool {
        BackupRootNodeAccess.shared.isTargetNode(for: self)
    }
    
    @objc func numberOfDevices(sdk: MEGASdk) -> String? {
        guard isBackupRootNode() else { return nil }
        let devices = sdk.numberChildFolders(forParent: self)
        
        if devices > 1 {
            return Strings.Localizable.CloudDrive.Node.Action.Devices.subtitle(devices)
        } else if devices > 0 {
            return Strings.Localizable.CloudDrive.Node.Action.Device.subtitle(devices)
        }
        return Strings.Localizable.General.emptyFolder
    }
}
