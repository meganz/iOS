
extension CloudDriveTableViewController {
    @objc func configureSwipeActionsForIndex(_ index: IndexPath) -> UISwipeActionsConfiguration {
        guard let node = self.cloudDrive?.node(at: index), MEGASdkManager.sharedMEGASdk().accessLevel(for: node) == .accessOwner else {
            return UISwipeActionsConfiguration(actions: [])
        }
        
        if MEGASdkManager.sharedMEGASdk().isNode(inRubbish: node) {
            if let restoreNode = MEGASdkManager.sharedMEGASdk().node(forHandle: node.restoreHandle),
               !MEGASdkManager.sharedMEGASdk().isNode(inRubbish: restoreNode) {
                let restoreAction = swipeAction(image: Asset.Images.NodeActions.restore.image.withTintColor(.white), backgroundColor: UIColor.mnz_turquoise(for: traitCollection)) { [weak self] in
                    node.mnz_restore()
                    self?.setTableViewEditing(false, animated: true)
                }
                
                return UISwipeActionsConfiguration(actions: [restoreAction])
            }
        } else {
            let shareLinkAction = swipeAction(image: Asset.Images.Generic.link.image.withTintColor(.white), backgroundColor: UIColor.systemOrange) { [weak self] in
                if MEGAReachabilityManager.isReachableHUDIfNot() {
                    CopyrightWarningViewController.presentGetLinkViewController(for: [node], in: UIApplication.mnz_presentingViewController())
                }
                self?.setTableViewEditing(false, animated: true)
            }
            
            let downloadAction = swipeAction(image: Asset.Images.NodeActions.offline.image.withTintColor(.white), backgroundColor: UIColor.mnz_turquoise(for: traitCollection)) { [weak self] in
                guard let self = self else { return }
                let nodeDownloadTransfer = CancellableTransfer(handle: node.handle, name: nil, appData: nil, priority: false, isFile: node.isFile(), type: .download)
                
                CancellableTransferRouter(presenter: self,
                                          transfers: [nodeDownloadTransfer],
                                          transferType: .download,
                                          isFolderLink: false).start()
                self.cloudDrive?.setEditMode(false)
            }
            
            if cloudDrive?.displayMode != .backup {
                let rubbishBinAction = swipeAction(image: Asset.Images.NodeActions.rubbishBin.image.withTintColor(.white), backgroundColor: UIColor.mnz_red(for: traitCollection)) { [weak self] in
                    self?.cloudDrive?.moveToRubbishBin(for: node)
                    self?.setTableViewEditing(false, animated: true)
                }
                
                return UISwipeActionsConfiguration(actions: [rubbishBinAction, shareLinkAction, downloadAction])
            }
            return UISwipeActionsConfiguration(actions: [shareLinkAction, downloadAction])
        }
        return UISwipeActionsConfiguration(actions: [])
    }
    
    private func swipeAction(image: UIImage, backgroundColor: UIColor, completion: @escaping () -> Void) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: nil, handler: { _, _, _ in
            completion()
        })
        
        action.image = image
        action.backgroundColor = backgroundColor
        
        return action
    }
}
