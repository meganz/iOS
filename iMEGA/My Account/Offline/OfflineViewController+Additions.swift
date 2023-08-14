import MEGADomain
import MEGASDKRepo

extension OfflineViewController {
    @objc func createOfflineViewModel() -> OfflineViewModel {
        OfflineViewModel(transferUseCase: NodeTransferUseCase(repo: NodeTransferRepository.newRepo))
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
            allNodes: nil
        )
    }
    
    @objc
    func configureNavigationBar() {
        let title = screenTitle
        setMenuCapableBackButtonWith(menuTitle: title)
        navigationItem.title = title
    }
    
    @objc func addSubscriptions() {
        viewModel.dispatch(.addSubscriptions)
    }
    
    @objc func removeSubscriptions() {
        viewModel.dispatch(.removeSubscriptions)
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
}
