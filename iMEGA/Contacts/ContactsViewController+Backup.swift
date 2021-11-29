
extension ContactsViewController {
    
    @objc func prepareSharedBackupFolderAlert(completion: @escaping () -> Void) {
        var message = ""
        var isInfoAlert = true
        if let nodes = nodesArray as? [MEGANode] {
            if nodes.allSatisfy({ $0.isBackupNode() || $0.isBackupRootNode() }) {
                message = nodes.count > 1 ?
                    NSLocalizedString("dialog.share.backup.folders.warning.message", comment: "") :
                    NSLocalizedString("dialog.share.backup.folder.warning.message", comment: "")
            } else {
                message = NSLocalizedString("dialog.share.backup.non.backup.folders.warning.message", comment: "")
                isInfoAlert = false
            }
        } else {
            message = NSLocalizedString("dialog.share.backup.folder.warning.message", comment: "")
        }
        
        let alert = UIAlertController(title: NSLocalizedString("permissions", comment: ""),
                                      message: message,
                                      preferredStyle: .alert)
        
        if isInfoAlert {
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .cancel) { _ in
                completion()
            })
        } else {
            alert.addAction(UIAlertAction(title: NSLocalizedString("yes", comment: ""), style: .default) { _ in
                completion()
            })
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel))
        }
    
        present(alert, animated: true, completion: nil)
    }
    
    @objc func isAnyBackupNodeBeingManaged() -> Bool {
        guard let nodes = nodesArray as? [MEGANode] else {
            guard let node = node else { return false }
            return node.isBackupNode() || node.isBackupRootNode()
        }
        
        return !(nodes.allSatisfy { !$0.isBackupNode() && !$0.isBackupRootNode() })
    }
    
    @objc func areAllShareNodesBackupNodes() -> Bool {
        guard let nodes = nodesArray as? [MEGANode] else {
            guard let node = node else { return false }
            return node.isBackupNode() || node.isBackupRootNode()
        }
        
        return nodes.allSatisfy { $0.isBackupNode() || $0.isBackupRootNode() }
    }
    
    @objc func shareBackupAndNonBackupNodesWithLevel(_ shareType: MEGAShareType) {
        guard let nodes = nodesArray as? [MEGANode] else {
            guard let node = node else { return }
            node.isBackupNode() || node.isBackupRootNode() ?
                shareNodes(withLevel: .accessRead, nodes: [node]) :
                shareNodes(withLevel: shareType, nodes: [node])
            return
        }
        let backupFolders = nodes.filter{$0.isBackupNode() || $0.isBackupRootNode()}
        let nonBackupFolders = Array(Set(backupFolders).symmetricDifference(Set(nodes)))
        
        shareNodes(withLevel: .accessRead, nodes: backupFolders)
        shareNodes(withLevel: shareType, nodes: nonBackupFolders)
    }
}
