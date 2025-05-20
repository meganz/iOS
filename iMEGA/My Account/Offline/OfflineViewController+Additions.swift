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
    
    @objc
    func initFullScreenPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController) {
        AudioPlayerManager.shared.initFullScreenPlayer(
            node: node,
            fileLink: fileLink,
            filePaths: filePaths,
            isFolderLink: isFolderLink,
            presenter: presenter,
            messageId: .invalid,
            chatId: .invalid,
            isFromSharedItem: false,
            allNodes: nil
        )
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
}

extension OfflineViewController: AudioPlayerPresenterProtocol {
    public func updateContentView(_ height: CGFloat) {
        additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
    }
    
    public func hasUpdatedContentView() -> Bool {
        additionalSafeAreaInsets.bottom != 0
    }
}
