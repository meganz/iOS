

class ExplorerBaseViewController: UIViewController {
    private lazy var toolbar = UIToolbar()
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
                shareAction: shareBarButtonPressed,
                moveAction: moveBarButtonPressed,
                copyAction: copyBarButtonPressed,
                deleteAction: deleteButtonPressed
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
        
        SVProgressHUD.show(Asset.Images.Hud.hudDownload.image,
                           status: Strings.Localizable.downloadStarted)
        selectedNodes.forEach { node in
            if node.mnz_downloadNode() {
                downloadStarted(forNode: node)
            }
        }
        
        endEditingMode()
    }
    
    fileprivate func shareBarButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        
        let activityVC = UIActivityViewController(forNodes: selectedNodes, sender: button)
        activityVC.completionWithItemsHandler = { [weak self] activityType, _, _, _ in
            self?.endEditingMode()
        }
        present(activityVC, animated: true)
    }
    
    fileprivate func deleteButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty,
              let rubbishBinNode = MEGASdkManager.sharedMEGASdk().rubbishNode else {
            return
        }
        
        let moveRequestDelegate = MEGAMoveRequestDelegate(
            files: UInt(selectedNodes.count),
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
    
    //MARK:- Methods needs to be overriden by the subclass
    
    func selectedNodes() -> [MEGANode]? {
        fatalError("selectedNodes() method needs to be implemented by the subclass")
    }
    
    func endEditingMode() {
        fatalError("endEditingMode() method needs to be implemented by the subclass")
    }
    
    func downloadStarted(forNode node: MEGANode) { }
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
