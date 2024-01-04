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
    
    @objc func getRecentActions() {
        MEGASdk.shared.getRecentActionsAsync(sinceDays: 30, maxNodes: 500, delegate: RequestDelegate { [weak self] result in
            if case let .success(request) = result,
               let recentActionsBuckets = request.recentActionsBuckets {
                self?.recentActionBucketArray = recentActionsBuckets
                self?.getRecentActionsActivityIndicatorView?.stopAnimating()
                self?.tableView?.isHidden = false
                self?.tableView?.reloadData()
            }
        })
    }
    
    @objc func initFullScreenPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController) {
        CrashlyticsLogger.log(category: .audioPlayer, "Initializing Full Screen Player - node: \(String(describing: node)), fileLink: \(String(describing: fileLink)), filePaths: \(String(describing:filePaths)), isFolderLink: \(isFolderLink)")
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
    
    @objc func showRecentAction(bucket: MEGARecentActionBucket) {
        let factory = CloudDriveViewControllerFactory.make(nc: UINavigationController())
        let vc = factory.build(
            nodeSource: .recentActionBucket(bucket),
            options: .init(
                displayMode: .recents,
                shouldRemovePlayerDelegate: false
            )
        )
        delegate?.showSelectedNode(in: vc)
    }
}
