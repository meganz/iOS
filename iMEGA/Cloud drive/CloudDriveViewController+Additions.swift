
extension CloudDriveViewController {
    
    private func updatedParentNodeIfBelongs(_ nodeList: MEGANodeList) -> MEGANode? {
        nodeList
            .toNodeArray()
            .compactMap {
                if $0.handle == parentNode?.handle { return $0 }
                return nil
            }.first
    }
    
    @IBAction func actionsTouchUpInside(_ sender: UIBarButtonItem) {
        guard let nodes = selectedNodesArray as? [MEGANode] else {
            return
        }

        let nodeActionsViewController = NodeActionViewController(nodes: nodes, delegate: self, displayMode: displayMode, isIncoming: isIncomingShareChildView, sender: sender)
        present(nodeActionsViewController, animated: true, completion: nil)
    }
    
    @objc func showBrowserNavigation(for nodes: [MEGANode], action: BrowserAction) {
        guard let navigationController = storyboard?.instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController, let browserVC = navigationController.viewControllers.first as? BrowserViewController else {
            return
        }
        
        browserVC.browserViewControllerDelegate = self
        browserVC.selectedNodesArray = nodes
        browserVC.browserAction = action
        
        present(navigationController, animated: true)
    }
    
    @objc func showShareFolderForNodes(_ nodes: [MEGANode]) {
        guard let navigationController =
                UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? MEGANavigationController, let contactsVC = navigationController.viewControllers.first as? ContactsViewController else {
            return
        }
        
        contactsVC.contatctsViewControllerDelegate = self
        contactsVC.nodesArray = nodes
        contactsVC.contactsMode = .shareFoldersWith
        
        present(navigationController, animated: true)
    }
    
    @objc func showSendToChat(_ nodes: [MEGANode]) {
        guard let navigationController =
                UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController, let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
            return
        }
        
        sendToViewController.nodes = nodes
        sendToViewController.sendMode = .cloud
        
        present(navigationController, animated: true)
    }
    
    @objc func prepareToMoveNodes(_ nodes: [MEGANode]) {
        showBrowserNavigation(for: nodes, action: .move)
    }
    
    @objc func removeLinksForNodes(_ nodes: [MEGANode]) {
        nodes.publicLinkedNodes().mnz_removeLinks()
    }

    @objc func updateParentNodeIfNeeded(_ updatedNodeList: MEGANodeList) {
        guard let updatedParentNode = updatedParentNodeIfBelongs(updatedNodeList) else { return }
        
        self.parentNode = updatedParentNode
        setNavigationBarButtons()
    }
}
