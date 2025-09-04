import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGARepo

extension OfflineViewController {
    @objc func createOfflineViewModel() -> OfflineViewModel {
        OfflineViewModel(
            offlineUseCase: OfflineUseCase(
                fileSystemRepository: FileSystemRepository.sharedRepo,
                offlineFilesRepository: OfflineFilesRepository.newRepo,
                nodeTransferRepository: NodeTransferRepository.newRepo
            ),
            megaStore: MEGAStore.shareInstance()
        )
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
        AudioPlayerManager.shared.playerHidden(isHidden, presenter: self)
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

extension OfflineViewController: AudioPlayerPresenterProtocol {
    public func updateContentView(_ height: CGFloat) {
        currentContentInsetHeight = height
        
        adjustSafeAreaBottomInset(currentContentInsetHeight)
    }
    
    public func hasUpdatedContentView() -> Bool {
        currentContentInsetHeight != 0
    }
}
