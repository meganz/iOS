
extension ContactsViewController {
    
    @objc func prepareSharedBackupFolderAlert(completion: @escaping () -> Void) {
        var message = ""
        var isInfoAlert = true
        if let nodes = nodesArray as? [MEGANode] {
            if nodes.allSatisfy({ $0.isBackupNode() || $0.isBackupRootNode() }) {
                message = nodes.count > 1 ?
                    Strings.Localizable.Dialog.Share.Backup.Folders.Warning.message:
                    Strings.Localizable.Dialog.Share.Backup.Folder.Warning.message
            } else {
                message = Strings.Localizable.Dialog.Share.Backup.Non.Backup.Folders.Warning.message
                isInfoAlert = false
            }
        } else {
            message = Strings.Localizable.Dialog.Share.Backup.Folder.Warning.message
        }
        
        let alert = UIAlertController(title: Strings.Localizable.permissions,
                                      message: message,
                                      preferredStyle: .alert)
        
        if isInfoAlert {
            alert.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .cancel) { _ in
                completion()
            })
        } else {
            alert.addAction(UIAlertAction(title: Strings.Localizable.yes, style: .default) { _ in
                completion()
            })
            
            alert.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
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
