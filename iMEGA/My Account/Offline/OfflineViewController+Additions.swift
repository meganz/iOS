import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGARepo

extension OfflineViewController {
    @objc func isCloudDriveRevampEnabled() -> Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .cloudDriveRevamp)
    }

    @objc func makeSelectActionSheet(for indexPath: IndexPath) -> ActionSheetAction {
        ActionSheetAction(
            title: Strings.Localizable.select,
            detail: nil,
            image: MEGAAssets.UIImage.selectItem,
            style: .default) { [weak self] in
                guard let self else { return }
                selectItem(at: indexPath)
            }
    }

    private func selectItem(at indexPath: IndexPath) {
        setEditMode(true)
        if isListViewModeSelected() {
            offlineTableView?.tableViewSelect(indexPath)
        } else {
            offlineCollectionView?.collectionViewSelect(indexPath)
        }
        reloadData()
    }

    @objc func createOfflineViewModel() -> OfflineViewModel {
        OfflineViewModel(
            offlineUseCase: OfflineUseCase(
                fileSystemRepository: FileSystemRepository.sharedRepo,
                offlineFilesRepository: OfflineFilesRepository.newRepo,
                nodeTransferRepository: NodeTransferRepository.newRepo
            ),
            megaStore: MEGAStore.shareInstance(),
            sortHeaderCoordinator: sortHeaderCoordinator
        ) { [weak self] updatedViewMode in
            guard let self,
                  (updatedViewMode == .list && !isListViewModeSelected())
                   || (updatedViewMode == .thumbnail && isListViewModeSelected()) else {
                return
            }
            changeViewModePreference()
        }
    }

    @objc func removeBannerContainer() {
        for viewController in children where viewController is BannerContainerViewController {
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
        }
    }

    @objc func setUpInvokeCommands() {
        viewModel.invokeCommand = { [weak self] command in
            guard let self else { return }
            
            excuteCommand(command)
        }
    }
    
    @objc func presentAudioPlayer(fileLink: String?, filePaths: [String]?) {
        if AudioPlayerManager.shared.isPlayerDefined() && AudioPlayerManager.shared.isPlayerAlive() {
            initMiniPlayer(fileLink: fileLink, filePaths: filePaths)
        } else {
            initFullScreenPlayer(fileLink: fileLink, filePaths: filePaths)
        }
    }
    
    private func initMiniPlayer(fileLink: String?, filePaths: [String]?) {
        AudioPlayerManager.shared.initMiniPlayer(
            node: nil,
            fileLink: fileLink,
            filePaths: filePaths,
            isFolderLink: false,
            presenter: self,
            shouldReloadPlayerInfo: true,
            shouldResetPlayer: true,
            isFromSharedItem: false
        )
    }
    
    private func initFullScreenPlayer(fileLink: String?, filePaths: [String]?) {
        AudioPlayerManager.shared.initFullScreenPlayer(
            node: nil,
            fileLink: fileLink,
            filePaths: filePaths,
            isFolderLink: false,
            presenter: self,
            messageId: .invalid,
            chatId: .invalid,
            isFromSharedItem: false,
            allNodes: nil
        )
    }
    
    @objc func updateAudioPlayerVisibility(_ isHidden: Bool) {
        guard AudioPlayerManager.shared.isPlayerAlive() else { return }
        AudioPlayerManager.shared.playerHidden(isHidden)
    }
    
    @objc
    func configureNavigationBar() {
        let title = screenTitle
        setMenuCapableBackButtonWith(menuTitle: title)
        navigationItem.title = title
    }
    
    @objc func dispatchOnViewAppearAction() {
        viewModel.dispatch(.onViewAppear)
    }
    
    @objc func dispatchOnViewWillDisappearAction() {
        viewModel.dispatch(.onViewWillDisappear)
    }
    
    @objc func removeOfflineItems(_ items: [URL]) {
        viewModel.dispatch(.removeOfflineItems(items))
    }
    
    @objc func selectedCountTitle() -> String {
        guard let selectedCount = selectedItems?.count,
              selectedCount > 0 else {
            return Strings.Localizable.selectTitle
        }
        return Strings.Localizable.General.Format.itemsSelected(selectedCount)
    }
    
    // MARK: - Private
    
    private var screenTitle: String {
        if let path = folderPathFromOffline?.lastPathComponent {
            return path
        } else {
            return Strings.Localizable.offline
        }
    }
    
    private func excuteCommand(_ command: OfflineViewModel.Command) {
        switch command {
        case .reloadUI:
            self.reloadUI()
        }
    }
    
    @objc func observeViewMode() {
        NotificationCenter.default.addObserver(self, selector: #selector(determineViewMode), name: .MEGAViewModePreferenceDidChange, object: nil)
    }
    
    @objc func refreshMiniPlayerIfNeeded() {
        if AudioPlayerManager.shared.isPlayerAlive(),
           let mainTabBarController = UIApplication.mainTabBarRootViewController() as? MainTabBarController {
            mainTabBarController.refreshBottomConstraint()
        }
    }
    
    @objc func adjustSafeAreaBottomInset(_ height: CGFloat) {
        additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
    }
}

extension OfflineViewController: AudioPlayerPresenterProtocol, BottomSafeAreaOverlayCoverStatusProviderProtocol {
    public var shouldShowSafeAreaOverlayCover: Bool {
        true
    }
    
    public func updateContentView(_ height: CGFloat) {
        currentContentInsetHeight = height
        
        adjustSafeAreaBottomInset(currentContentInsetHeight)
    }
    
    public func hasUpdatedContentView() -> Bool {
        currentContentInsetHeight != 0
    }
}

extension OfflineViewController {
    @objc func setupEditingToolbar() {
        guard editingToolbar == nil else { return }
        
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.isHidden = true
        toolbar.alpha = 0
        editingToolbar = toolbar
        
        view.addSubview(toolbar)
        
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func configureEditingToolbarItems() {
        guard let editingToolbar, let activityBarButtonItem, let deleteBarButtonItem else { return }
        
        let flexible = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        
        editingToolbar.items = [activityBarButtonItem, flexible, deleteBarButtonItem]
    }
    
    @objc func showEditingToolbar() {
        setEditingToolbarVisible(true)
    }

    @objc func hideEditingToolbar() {
        setEditingToolbarVisible(false)
    }
    
    private func setEditingToolbarVisible(_ visible: Bool) {
        guard let editingToolbar else { return }

        if visible {
            editingToolbar.isHidden = false
        }

        UIView.animate(withDuration: 0.25, animations: {
            editingToolbar.alpha = visible ? 1 : 0
        }, completion: { _ in
            editingToolbar.isHidden = !visible
        })
    }
    
    @objc func updateBottomInset(_ editing: Bool) {
        let toolbarHeight: CGFloat = editing ? 50 : 0
        
        adjustSafeAreaBottomInset(currentContentInsetHeight)
        
        if let table = offlineTableView?.tableView {
            table.contentInset.bottom = toolbarHeight
            table.verticalScrollIndicatorInsets.bottom = toolbarHeight
        }
        
        if let collection = offlineCollectionView?.collectionView {
            collection.contentInset.bottom = toolbarHeight
            collection.verticalScrollIndicatorInsets.bottom = toolbarHeight
        }
    }
}
