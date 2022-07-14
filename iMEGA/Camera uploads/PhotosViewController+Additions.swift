extension PhotosViewController {
    @IBAction func moreAction(_ sender: UIBarButtonItem) {
        let nodeActionsViewController = NodeActionViewController(nodes: selection.nodes, delegate: self, displayMode: .selectionToolBar, sender: sender)
        present(nodeActionsViewController, animated: true, completion: nil)
    }
    
    @objc func handleDownloadAction(for nodes: [MEGANode]) {
        TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
        let transfers = nodes.map {
            CancellableTransfer(handle: $0.handle, path: Helper.relativePathForOffline(), name: nil, appData: nil, priority: false, isFile: $0.isFile(), type: .download)
        }
        CancellableTransferRouter(presenter: self, transfers: transfers, transferType: .download).start()
        setEditing(false, animated: true)
    }
    
    @objc func showBrowserNavigation(for nodes: [MEGANode], action: BrowserAction) {
        guard let navigationController = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController,
              let browserVC = navigationController.viewControllers.first as? BrowserViewController else {
            return
        }
        browserVC.browserViewControllerDelegate = self
        browserVC.selectedNodesArray = nodes
        browserVC.browserAction = action
        present(navigationController, animated: true)
    }
    
    @objc func handleShareLink(for nodes: [MEGANode]) {
        guard MEGAReachabilityManager.isReachableHUDIfNot() else { return }
        CopyrightWarningViewController.presentGetLinkViewController(for: nodes, in: UIApplication.mnz_presentingViewController())
        setEditing(false, animated: true)
    }
    
    @objc func handleDeleteAction(for nodes: [MEGANode]) {
        guard let rubbish = MEGASdkManager.sharedMEGASdk().rubbishNode else { return }
        let delegate = MEGAMoveRequestDelegate(toMoveToTheRubbishBinWithFiles: nodes.contentCounts().fileCount,
                                               folders: nodes.contentCounts().folderCount) { [weak self] in
            self?.setEditing(false, animated: true)
        }
        nodes.forEach { MEGASdkManager.sharedMEGASdk().move($0, newParent: rubbish, delegate: delegate) }
    }
    
    func handleRemoveLinks(for nodes: [MEGANode]) {
        nodes.publicLinkedNodes().mnz_removeLinks()
        setEditing(false, animated: true)
    }
    
    private func handleExportFile(for nodes: [MEGANode], sender: Any) {
        let entityNodes = nodes.toNodeEntities()
        ExportFileRouter(presenter: self, sender: sender).export(nodes: entityNodes)
        setEditing(false, animated: true)
    }
    
    private func handleSendToChat(for nodes: [MEGANode]) {
        guard let navigationController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
              let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
            return
        }
        
        sendToViewController.nodes = nodes
        sendToViewController.sendMode = .cloud
        present(navigationController, animated: true)
        setEditing(false, animated: true)
    }
}

//MARK: - NodeActionViewControllerDelegate
extension PhotosViewController: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
        handleNodesAction(action: action, nodes: nodes, sender: sender)
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        handleNodesAction(action: action, nodes: [node], sender: sender)
    }

    private func handleNodesAction(action: MegaNodeActionType, nodes: [MEGANode], sender: Any) {
        switch action {
        case .download:
            handleDownloadAction(for: nodes)
        case .copy:
            showBrowserNavigation(for: nodes, action: .copy)
        case .move:
            showBrowserNavigation(for: nodes, action: .move)
        case .shareLink:
            handleShareLink(for: nodes)
        case .moveToRubbishBin:
            handleDeleteAction(for: nodes)
        case .exportFile:
            handleExportFile(for: nodes, sender: sender)
        case .sendToChat:
            handleSendToChat(for: nodes)
        case .removeLink:
            handleRemoveLinks(for: nodes)
        default:
            break
        }
    }
}

//MARK: - BrowserViewControllerDelegate and ContatctsViewControllerDelegate
extension PhotosViewController: BrowserViewControllerDelegate, ContatctsViewControllerDelegate {
    public func nodeEditCompleted(_ complete: Bool) {
        setEditing(false, animated: true)
    }
}
