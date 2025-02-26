extension PhotosViewController {
    
    @objc func setToolbarActionsEnabled(in toolbar: UIToolbar?, isEnabled: Bool) {
        toolbar?.items?.forEach { $0.isEnabled = isEnabled }
    }
    
    @objc func updateBarButtonItems(in toolbar: UIToolbar?) {
        
        guard let toolbar else { return }
        
        let flexibleItem = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        
        let createBarButtonItem = { (image: UIImage, action: Selector) -> UIBarButtonItem in
            let item = UIBarButtonItem(
                image: image,
                style: .plain,
                target: self,
                action: action
            )
            item.isEnabled = false
            return item
        }
        
        let toolBarItems = [
            createBarButtonItem(.offline, #selector(downloadAction)),
            flexibleItem,
            createBarButtonItem(.link, #selector(shareLinkAction)),
            flexibleItem,
            createBarButtonItem(.addTo, #selector(addToAction)),
            flexibleItem,
            createBarButtonItem(.rubbishBin, #selector(deleteAction)),
            flexibleItem,
            createBarButtonItem(.moreNavigationBar, #selector(moreAction))
        ]
        
        toolbar.setItems(toolBarItems, animated: false)
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
