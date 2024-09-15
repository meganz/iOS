extension CloudDriveTableViewController {
    @objc func configureSwipeActionsForIndex(_ index: IndexPath) -> UISwipeActionsConfiguration {
        guard let node = self.cloudDrive?.node(at: index), MEGASdk.shared.accessLevel(for: node) == .accessOwner else {
            return UISwipeActionsConfiguration(actions: [])
        }
        
        if MEGASdk.shared.isNode(inRubbish: node) {
            if let restoreNode = MEGASdk.shared.node(forHandle: node.restoreHandle),
               !MEGASdk.shared.isNode(inRubbish: restoreNode) {
                let restoreAction = swipeAction(image: UIImage.restore.withTintColor(UIColor.whiteFFFFFF), backgroundColor: UIColor.mnz_turquoise(for: traitCollection)) { [weak self] in
                    node.mnz_restore()
                    self?.setTableViewEditing(false, animated: true)
                }
                
                return UISwipeActionsConfiguration(actions: [restoreAction])
            }
        } else {
            let shareLinkAction = swipeAction(image: UIImage.link.withTintColor(UIColor.whiteFFFFFF), backgroundColor: UIColor.systemOrange) { [weak self] in
                if MEGAReachabilityManager.isReachableHUDIfNot() {
                    GetLinkRouter(presenter: UIApplication.mnz_presentingViewController(),
                                  nodes: [node]).start()
                }
                self?.setTableViewEditing(false, animated: true)
            }
            
            let downloadAction = swipeAction(image: UIImage.offline.withTintColor(UIColor.whiteFFFFFF), backgroundColor: UIColor.mnz_turquoise(for: traitCollection)) { [weak self] in
                guard let self else { return }
                let nodeDownloadTransfer = CancellableTransfer(handle: node.handle, name: nil, appData: nil, priority: false, isFile: node.isFile(), type: .download)
                
                CancellableTransferRouter(presenter: self,
                                          transfers: [nodeDownloadTransfer],
                                          transferType: .download,
                                          isFolderLink: false).start()
            }
            
            if cloudDrive?.displayMode != .backup {
                let rubbishBinAction = swipeAction(image: UIImage.rubbishBin.withTintColor(UIColor.whiteFFFFFF), backgroundColor: UIColor.mnz_red(for: traitCollection)) { [weak self] in
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
