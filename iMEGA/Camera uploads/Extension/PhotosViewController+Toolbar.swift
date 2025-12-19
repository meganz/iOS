import MEGAAppPresentation
import MEGAAssets

extension PhotosViewController {
    
    @objc func setToolbarActionsEnabled(in toolbar: UIToolbar?, isEnabled: Bool) {
        toolbar?.items?.forEach { $0.isEnabled = isEnabled }
    }
    
    @objc func setUpToolbar() {
        guard let toolbar, let tabBarController else { return }
        
        toolbar.alpha = 0.0
        objcWrapper_updateNavigationTitle(withSelectedPhotoCount: 0)
        configureBarButtonItems(on: toolbar)
        
        tabBarController.view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        let bottomAnchor = tabBarController.tabBar.safeAreaLayoutGuide.bottomAnchor
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: tabBarController.tabBar.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: tabBarController.tabBar.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Private
    
    private func buildBarItem(with icon: UIImage, action: Selector) -> UIBarButtonItem {
        let item = UIBarButtonItem(
            image: icon,
            style: .plain,
            target: self,
            action: action
        )
        
        item.isEnabled = false
        
        return item
    }
    
    private func configureBarButtonItems(on toolbar: UIToolbar?) {
        if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
            configureBarItemsWithGroups(on: toolbar)
        } else {
            configureToolbarLegacy(on: toolbar)
        }
    }
    
    @available(iOS 26.0, *)
    private func configureBarItemsWithGroups(on toolbar: UIToolbar?) {
        guard let toolbar else { return }
        
        toolbar.items = [
            buildBarItem(with: MEGAAssets.UIImage.offline, action: #selector(downloadAction)),
            buildBarItem(with: MEGAAssets.UIImage.link, action: #selector(shareLinkAction)),
            buildBarItem(with: MEGAAssets.UIImage.addTo, action: #selector(addToAction)),
            buildBarItem(with: MEGAAssets.UIImage.rubbishBin, action: #selector(deleteAction)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            buildBarItem(with: MEGAAssets.UIImage.moreNavigationBar, action: #selector(moreAction))
        ]
    }
    
    @objc private func configureToolbarLegacy(on toolbar: UIToolbar?) {
        guard let toolbar else { return }
        
        toolbar.backgroundColor = .surface1Background()
        
        let flexibleItem = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        
        toolbar.items = [
            buildBarItem(with: MEGAAssets.UIImage.offline, action: #selector(downloadAction)),
            flexibleItem,
            buildBarItem(with: MEGAAssets.UIImage.link, action: #selector(shareLinkAction)),
            flexibleItem,
            buildBarItem(with: MEGAAssets.UIImage.addTo, action: #selector(addToAction)),
            flexibleItem,
            buildBarItem(with: MEGAAssets.UIImage.rubbishBin, action: #selector(deleteAction)),
            flexibleItem,
            buildBarItem(with: MEGAAssets.UIImage.moreNavigationBar, action: #selector(moreAction))
        ]
    }
    
    @objc private func downloadAction(_ sender: UIBarButtonItem) {
        handleDownloadAction(for: selection.nodes)
    }
    
    @objc private func shareLinkAction(_ sender: UIBarButtonItem) {
        handleShareLink(for: selection.nodes)
    }
    
    @objc private func moveAction(_ sender: UIBarButtonItem) {
        showBrowserNavigation(for: selection.nodes, action: .move)
    }
    
    @objc private func addToAction(_ sender: UIBarButtonItem) {
        addToAlbum(nodes: selection.nodes.toNodeEntities())
    }
    
    @objc private func deleteAction(_ sender: UIBarButtonItem) {
        handleDeleteAction(for: selection.nodes)
    }
    
    @objc private func moreAction(_ sender: UIBarButtonItem) {
        let nodeActionsViewController = NodeActionViewController(nodes: selection.nodes, delegate: self, displayMode: .photosTimeline, sender: sender)
        nodeActionsViewController.accessoryActionDelegate = defaultNodeAccessoryActionDelegate
        present(nodeActionsViewController, animated: true, completion: nil)
    }
}
