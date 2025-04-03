import MEGADomain
import MEGASDKRepo

extension FolderLinkViewController: FolderLinkContextMenuDelegate {
    private func contextMenuConfiguration() -> CMConfigEntity? {
        guard let parentNode = parentNode else { return nil }

        return CMConfigEntity(
            menuType: .menu(type: .folderLink),
            viewMode: isListViewModeSelected() ? .list : .thumbnail,
            sortType: SortOrderType(megaSortOrderType: Helper.sortType(for: parentNode)).megaSortOrderType.toSortOrderEntity(),
            showMediaDiscovery: containsMediaFiles()
        )
    }

    @objc func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(
            displayMenuDelegate: self,
            quickActionsMenuDelegate: self,
            uploadAddMenuDelegate: self,
            rubbishBinMenuDelegate: self,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
        )
        setMoreButton()
    }

    @objc func setNavigationBarButton(_ editing: Bool) {
        navigationItem.rightBarButtonItem = editing ? editBarButtonItem : moreBarButtonItem
    }

    @objc func setMoreButton() {
        guard let config = contextMenuConfiguration() else { return }
        moreBarButtonItem.menu = contextMenuManager?.contextMenu(with: config)
    }

    private func updateContextMenu() {
        if let contextMenuManager,
           let menuConfig = contextMenuConfiguration(),
           let updatedMenu = contextMenuManager.contextMenu(with: menuConfig) {
            moreBarButtonItem = UIBarButtonItem(image: UIImage.moreNavigationBar,
                                                   menu: updatedMenu)
            navigationItem.rightBarButtonItems = [moreBarButtonItem]
        }
    }

    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        switch action {
        case .select:
            select()
        case .thumbnailView, .listView:
            if isListViewModeSelected() && action == .thumbnailView || !isListViewModeSelected() && action == .listView {
                changeViewModePreference()
                updateContextMenu()
            }
        case .mediaDiscovery:
            showMediaDiscovery()
        default:
            break
        }
    }

    func quickActionsMenu(didSelect action: QuickActionEntity, needToRefreshMenu: Bool) {
        switch action {
        case .shareLink:
            shareLinkAction(moreBarButtonItem)
        case .download:
            guard let node = parentNode else { return }
            download([node])
        case .sendToChat:
            showSendToChat()
        default:
            break
        }
    }

    func uploadAddMenu(didSelect action: UploadAddActionEntity) {
        switch action {
        case .importFolderLink:
            importFilesFromFolderLink()
        default:
            break
        }
    }

    func rubbishBinMenu(didSelect action: RubbishBinActionEntity) {
        switch action {
        case .restore:
            guard let node = parentNode else { return }
            node.mnz_restore()
            navigationController?.dismiss(animated: true)
        default:
            break
        }
    }

    func sortMenu(didSelect sortType: SortOrderType) {
        Helper.save(sortType.megaSortOrderType, for: parentNode)
        reloadUI()
        updateContextMenu()
    }
}
