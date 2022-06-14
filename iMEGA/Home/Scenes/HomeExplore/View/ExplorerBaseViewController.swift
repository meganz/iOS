

class ExplorerBaseViewController: UIViewController {
    lazy var toolbar = UIToolbar()
    private var explorerToolbarConfigurator: ExplorerToolbarConfigurator?
    
    var isToolbarShown: Bool {
        return toolbar.superview != nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isToolbarShown {
            endEditingMode()
        }
    }
    
    func showToolbar() {
        guard let tabBarController = tabBarController, toolbar.superview == nil else { return }
        
        if !tabBarController.view.subviews.contains(toolbar) {
            toolbar.alpha = 0.0
            tabBarController.view.addSubview(toolbar)
            toolbar.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
            toolbar.autoPinEdge(.top, to: .top, of: tabBarController.tabBar)
            let bottomAnchor: NSLayoutYAxisAnchor = tabBarController.tabBar.safeAreaLayoutGuide.bottomAnchor
            toolbar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
            toolbar.autoPinEdge(.leading, to: .leading, of: tabBarController.tabBar)
            toolbar.autoPinEdge(.trailing, to: .trailing, of: tabBarController.tabBar)
            
            UIView.animate(withDuration: 0.3) {
                self.toolbar.alpha = 1.0
            }
        }
    }
    
    func hideToolbar() {
        guard toolbar.superview != nil else { return }
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = 0.0
        } completion: { _ in
            self.toolbar.removeFromSuperview()
        }
    }
    
    func configureToolbarButtons() {
        if explorerToolbarConfigurator == nil {
            explorerToolbarConfigurator = ExplorerToolbarConfigurator(
                downloadAction: downloadBarButtonPressed,
                shareLinkAction: shareLinkBarButtonPressed,
                moveAction: moveBarButtonPressed,
                copyAction: copyBarButtonPressed,
                deleteAction: deleteButtonPressed,
                moreAction: didPressedMoreBarButton
            )
        }
        
        toolbar.items = explorerToolbarConfigurator?.toolbarItems(forNodes: selectedNodes())
    }
    
    // MARK:- Toolbar Button actions
    fileprivate func downloadBarButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
                  return
              }

        TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
        let transfers = selectedNodes.map { CancellableTransfer(handle: $0.handle, path: Helper.relativePathForOffline(), name: nil, appData: nil, priority: false, isFile: $0.isFile(), type: .download) }
        CancellableTransferRouter(presenter: self, transfers: transfers, transferType: .download).start()
        endEditingMode()
    }
    
    fileprivate func shareLinkBarButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
                  return
              }
        
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            CopyrightWarningViewController.presentGetLinkViewController(
                for: selectedNodes,
                in: UIApplication.mnz_presentingViewController()
            )
            endEditingMode()
        }
    }
    
    fileprivate func deleteButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty,
              let rubbishBinNode = MEGASdkManager.sharedMEGASdk().rubbishNode else {
                  return
              }
        
        let moveRequestDelegate = MEGAMoveRequestDelegate(
            toMoveToTheRubbishBinWithFiles: UInt(selectedNodes.count),
            folders: 0) { [weak self] in
                self?.endEditingMode()
            }
        
        selectedNodes.forEach {
            MEGASdkManager.sharedMEGASdk().move(
                $0,
                newParent: rubbishBinNode,
                delegate: moveRequestDelegate
            ) }
    }
    
    fileprivate func moveBarButtonPressed(_ button: UIBarButtonItem) {
        openBrowserViewController(withAction: .move)
    }
    
    fileprivate func copyBarButtonPressed(_ button: UIBarButtonItem) {
        openBrowserViewController(withAction: .copy)
    }
    
    private func openBrowserViewController(withAction action: BrowserAction) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty,
              let navigationController = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController,
              let browserVC = navigationController.viewControllers.first as? BrowserViewController else {
                  return
              }
        
        browserVC.selectedNodesArray = selectedNodes
        browserVC.browserAction = action
        browserVC.browserViewControllerDelegate = self
        present(navigationController, animated: true)
    }
    
    fileprivate func didPressedMoreBarButton(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        
        let nodeActionsViewController = NodeActionViewController(nodes: selectedNodes, delegate: self, displayMode: .selectionToolBar, sender: button)
        present(nodeActionsViewController, animated: true, completion: nil)
    }
    
    fileprivate func didPressedExportFile(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        
        let entityNodes = selectedNodes.map { NodeEntity(node: $0) }
        ExportFileRouter(presenter: self, sender: button).export(nodes: entityNodes)
        endEditingMode()
    }
    
    fileprivate func didPressedSendToChat(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        guard let navigationController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
              let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
            return
        }
        
        sendToViewController.nodes = selectedNodes
        sendToViewController.sendMode = .cloud
        present(navigationController, animated: true)
        endEditingMode()
    }
    
    //MARK:- Methods needs to be overriden by the subclass
    
    func selectedNodes() -> [MEGANode]? {
        fatalError("selectedNodes() method needs to be implemented by the subclass")
    }
    
    func endEditingMode() {
        fatalError("endEditingMode() method needs to be implemented by the subclass")
    }
}

extension ExplorerBaseViewController: TraitEnviromentAware {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        AppearanceManager.forceToolbarUpdate(toolbar, traitCollection: traitCollection)
    }
}

extension ExplorerBaseViewController: BrowserViewControllerDelegate {
    func nodeEditCompleted(_ complete: Bool) {
        endEditingMode()
    }
}

//MARK: - NodeActionViewControllerDelegate
extension ExplorerBaseViewController: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
        handleNodesAction(action: action, nodes: nodes, sender: sender)
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        handleNodesAction(action: action, nodes: [node], sender: sender)
    }

    private func handleNodesAction(action: MegaNodeActionType, nodes: [MEGANode], sender: Any) {
        guard let sender = sender as? UIBarButtonItem else { return }
        switch action {
        case .download:
            downloadBarButtonPressed(sender)
        case .copy:
            copyBarButtonPressed(sender)
        case .move:
            moveBarButtonPressed(sender)
        case .shareLink:
            shareLinkBarButtonPressed(sender)
        case .moveToRubbishBin:
            deleteButtonPressed(sender)
        case .exportFile:
            didPressedExportFile(sender)
        case .sendToChat:
            didPressedSendToChat(sender)
        default:
            break
        }
    }
}
