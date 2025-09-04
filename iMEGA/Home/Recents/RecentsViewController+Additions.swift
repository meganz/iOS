import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAFoundation

extension RecentsViewController {
    
    @objc func makeRecentsViewModel() -> RecentsViewModel {
        let recentNodesUseCase = RecentNodesUseCase(
            recentNodesRepository: RecentNodesRepository.newRepo,
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
            userUpdateRepository: UserUpdateRepository.newRepo,
            requestStatesRepository: RequestStatesRepository.newRepo,
            nodeRepository: NodeRepository.newRepo,
            hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) }
        )
        
        return RecentsViewModel(recentNodesUseCase: recentNodesUseCase)
    }
    
    @objc func onViewDidLoad() {
        viewModel.recentActionsUpdates = { [weak self] in
            self?.getRecentActions()
        }
        viewModel.onViewDidLoad()
    }
    
    @objc func showContactVerificationView(forUserEmail userEmail: String) {
        guard let user = MEGASdk.sharedSdk.contact(forEmail: userEmail),
              let verifyCredentialsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "VerifyCredentialsViewControllerID") as? VerifyCredentialsViewController else {
            return
        }
        
        verifyCredentialsVC.user = user
        verifyCredentialsVC.userName = user.mnz_displayName ?? user.email
        verifyCredentialsVC.setContactVerification(true)
        verifyCredentialsVC.statusUpdateCompletionBlock = { [weak self] in
            self?.getRecentActions()
        }
        
        let navigationController = MEGANavigationController(rootViewController: verifyCredentialsVC)
        navigationController.addRightCancelButton()
        self.present(navigationController, animated: true)
    }
    
    @objc func getRecentActions() {
        Task { await getRecentActions() }
    }
    
    @objc func presentAudioPlayer(node: MEGANode) {
        if AudioPlayerManager.shared.isPlayerDefined() && AudioPlayerManager.shared.isPlayerAlive() {
            initMiniPlayer(node: node)
        } else {
            initFullScreenPlayer(node: node)
        }
    }
    
    private func initMiniPlayer(node: MEGANode?) {
        AudioPlayerManager.shared.initMiniPlayer(
            node: node,
            fileLink: nil,
            filePaths: nil,
            isFolderLink: false,
            presenter: self,
            shouldReloadPlayerInfo: true,
            shouldResetPlayer: true,
            isFromSharedItem: false
        )
    }
    
    private func initFullScreenPlayer(node: MEGANode?) {
        AudioPlayerManager.shared.initFullScreenPlayer(
            node: node,
            fileLink: nil,
            filePaths: nil,
            isFolderLink: false,
            presenter: self,
            messageId: .invalid,
            chatId: .invalid,
            isFromSharedItem: false,
            allNodes: nil
        )
    }
    
    @objc func showRecentAction(bucket: MEGARecentActionBucket) {
        let factory = CloudDriveViewControllerFactory.make(nc: UINavigationController())
        let vc = factory.build(
            nodeSource: .recentActionBucket(
                MEGARecentActionBucketTrampoline(
                    bucket: bucket,
                    parentNodeProvider: { parentHandle in
                        MEGASdk.shared.node(forHandle: parentHandle)?.toNodeEntity()
                    }
                )
            ),
            config: .init(
                displayMode: .recents,
                shouldRemovePlayerDelegate: false
            )
        )
        delegate?.showSelectedNode(in: vc)
    }
    
    @objc func configureTokenColors() {
        view.backgroundColor = TokenColors.Background.page
        tableView?.backgroundColor = TokenColors.Background.page
        tableView?.separatorColor = TokenColors.Border.strong
    }
    
    @objc func heightForHeaderIn(section: Int, expectedValueForVisibleHeader: CGFloat) -> CGFloat {
        guard let recentActionBucket = recentActionBucketArray[safe: section], let timestamp = recentActionBucket.timestamp else {
            return 0
        }
        
        if section > 0 {
            if let previousRecentActionBucket = recentActionBucketArray[safe: section - 1],
               let previousTimeStamp = previousRecentActionBucket.timestamp {
                if previousTimeStamp.isSameDay(date: timestamp) {
                    return 0
                }
            }
        }
        
        return expectedValueForVisibleHeader
    }
    
    private func getRecentActions() async {
        let excludeSensitives = await shouldExcludeSensitive()
        
        MEGASdk.shared.getRecentActionsAsync(sinceDays: 30, maxNodes: 500, excludeSensitives: excludeSensitives, delegate: RequestDelegate { @MainActor [weak self] result in
            if case let .success(request) = result,
               let recentActionsBuckets = request.recentActionsBuckets {
                self?.recentActionBucketArray = recentActionsBuckets
                self?.getRecentActionsActivityIndicatorView?.stopAnimating()
                self?.tableView?.isHidden = false
                self?.tableView?.reloadData()
            }
        })
    }
    
    private func shouldExcludeSensitive() async -> Bool {
        guard DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) else {
            return false
        }
        
        return await !ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo)
            .fetchSensitiveAttribute()
            .showHiddenNodes
    }
}

extension RecentsViewController: AudioPlayerPresenterProtocol {
    public func updateContentView(_ height: CGFloat) {
        additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
        didUpdateMiniPlayerHeight?(height)
    }
    
    public func hasUpdatedContentView() -> Bool {
        additionalSafeAreaInsets.bottom != 0
    }
}
