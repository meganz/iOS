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
}
