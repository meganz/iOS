
extension MEGANode {
    @objc func isBackupNode() -> Bool {
        deviceId?.isEmpty == false
    }
    
    @objc func isBackupRootNode() -> Bool {
        BackupRootNodeAccess.shared.isTargetNode(for: self)
    }
}
