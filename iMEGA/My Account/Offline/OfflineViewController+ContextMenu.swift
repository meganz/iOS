import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n

extension OfflineViewController: DisplayMenuDelegate {
    // MARK: - Context Menus configuration
    func contextMenuConfiguration() -> CMConfigEntity {
        return CMConfigEntity(menuType: .menu(type: .display),
                              viewMode: isListViewModeSelected() ? .list : .thumbnail,
                              sortType: SortOrderType(megaSortOrderType: Helper.sortType(for: currentOfflinePath)).megaSortOrderType.toSortOrderEntity(),
                              isOfflineFolder: true)
    }
    
    @objc func configureNavigationBarButtons() {
        guard !DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .cloudDriveRevamp) else {
            navigationItem.rightBarButtonItems = nil
            return
        }

        contextMenuManager = ContextMenuManager(displayMenuDelegate: self, createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo))
        
        contextBarButtonItem = UIBarButtonItem(image: MEGAAssets.UIImage.moreNavigationBar,
                                               menu: contextMenuManager?.contextMenu(with: contextMenuConfiguration()))
        
        contextBarButtonItem.accessibilityLabel = Strings.Localizable.more
        
        navigationItem.rightBarButtonItems = [contextBarButtonItem]
    }
    
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        switch action {
        case .select:
            changeEditingModeStatus()
        case .thumbnailView, .listView:
            if isListViewModeSelected() && action == .thumbnailView || !isListViewModeSelected() && action == .listView {
                changeViewModePreference()
            }
        default: break
        }
        
        if needToRefreshMenu {
            configureNavigationBarButtons()
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        Helper.save(sortType.megaSortOrderType, for: currentOfflinePath)
        nodesSortTypeHasChanged()
        configureNavigationBarButtons()
    }
}
