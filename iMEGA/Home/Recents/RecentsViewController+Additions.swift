import MEGADesignToken
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

extension RecentsViewController {
    
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
    
    @objc func shouldReloadOnUserUpdate(userList: MEGAUserList) -> Bool {
        userList
            .toUserEntities()
            .contains(where: { $0.changes.contains(.CCPrefs) })
    }
    
    @objc func getRecentActions() {
        Task { await getRecentActions() }
    }
    
    @objc func initFullScreenPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController) {
        CrashlyticsLogger.log(category: .audioPlayer, "Initializing Full Screen Player - node: \(String(describing: node)), fileLink: \(String(describing: fileLink)), filePaths: \(String(describing: filePaths)), isFolderLink: \(isFolderLink)")
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
    
    @objc func showRecentAction(bucket: MEGARecentActionBucket) {
        let factory = CloudDriveViewControllerFactory.make(nc: UINavigationController())
        let vc = factory.build(
            nodeSource: .recentActionBucket(bucket),
            config: .init(
                displayMode: .recents,
                shouldRemovePlayerDelegate: false
            )
        )
        delegate?.showSelectedNode(in: vc)
    }

    @objc func configureTokenColors() {
        tableView?.backgroundColor = TokenColors.Background.page
        tableView?.separatorColor = TokenColors.Border.strong
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
        guard DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) else {
            return false
        }
        
        return await !ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo)
            .fetchSensitiveAttribute()
            .showHiddenNodes
    }
}
