
extension OfflineViewController: DisplayMenuDelegate {
    //MARK: - Context Menus configuration
    func contextMenuConfiguration() -> CMConfigEntity {
        return CMConfigEntity(menuType: .display,
                              viewMode: isListViewModeSelected() ? ViewModePreference.list : ViewModePreference.thumbnail,
                              sortType: SortOrderType(megaSortOrderType: Helper.sortType(for: currentOfflinePath)),
                              isOfflineFolder: true)
    }
    
    @objc func setNavigationBarButtons() {
        contextMenuManager = ContextMenuManager(displayMenuDelegate: self, createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository()))
        
        if #available(iOS 14.0, *) {
            contextBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image,
                                                   menu: contextMenuManager?.contextMenu(with: contextMenuConfiguration()))
        } else {
            contextBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image, style: .plain, target: self, action: #selector(presentActionSheet(sender:)))
        }
        
        contextBarButtonItem.accessibilityLabel = Strings.Localizable.more
        
        navigationItem.rightBarButtonItems = [contextBarButtonItem]
    }
    
    @objc private func presentActionSheet(sender: Any) {
        guard let actions = contextMenuManager?.actionSheetActions(with: contextMenuConfiguration()) else { return }
        presentActionSheet(actions: actions)
    }
    
    //MARK: - DisplayMenuDelegate functions
    @objc func presentActionSheet(actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions,
                                                      headerTitle: nil,
                                                      dismissCompletion: nil,
                                                      sender: nil)

        self.present(actionSheetVC, animated: true)
    }
    
    func displayMenu(didSelect action: DisplayAction, needToRefreshMenu: Bool) {
        switch action {
        case .select:
            changeEditingModeStatus()
        case .thumbnailView, .listView:
            changeViewModePreference()
        default: break
        }
        
        if #available(iOS 14, *), needToRefreshMenu {
            setNavigationBarButtons()
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        Helper.save(sortType.megaSortOrderType, for: currentOfflinePath)
        nodesSortTypeHasChanged()
        if #available(iOS 14, *) {
            setNavigationBarButtons()
        }
    }
    
    func showActionSheet(with actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions, headerTitle: nil, dismissCompletion: nil, sender: nil)
        present(actionSheetVC, animated: true)
    }
}
