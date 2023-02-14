import MEGADomain

extension CustomModalAlertViewController {
    func configureForUpgradeSecurity() {
        image = Asset.Images.MyAccount.upgradeSecurity.image
        viewTitle = Strings.Localizable.Account.UpgradeSecurity.title
        
        let outSharedFolders = MEGASdkManager.sharedMEGASdk().outShares(.defaultAsc)
        let outSharedFolderNameList = outSharedFolders.toShareEntities().compactMap { shareEntity in
            let node = MEGASdkManager.sharedMEGASdk().node(forHandle: shareEntity.nodeHandle)
            return node?.name
        }
        
        detail = Strings.Localizable.Account.UpgradeSecurity.Message.upgrade
        if !outSharedFolderNameList.isEmpty {
            let folderNames = outSharedFolderNameList.joined(separator: ", ")
            let folderNameMessage = Strings.Localizable.Account.UpgradeSecurity.Message.sharedFolderNames(outSharedFolderNameList.count)
                .replacingOccurrences(of: "[A]", with: folderNames)
            detail = detail + "\n\n" + folderNameMessage
        }
        
        firstButtonTitle = Strings.Localizable.ok
        dismissButtonStyle = MEGACustomButtonStyle.basic.rawValue
        dismissButtonTitle = Strings.Localizable.cancel
        
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                Task.detached { @MainActor in
                    do {
                        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
                        let _ = try await accountUseCase.upgradeSecurity()
                    } catch {
                        SVProgressHUD.showError(withStatus: error.localizedDescription)
                    }
                }
            })
        }

        dismissCompletion = { [weak self] in
            self?.cancelSecurityUpgrade()
        }
    }
    
    private func cancelSecurityUpgrade() {
        MEGALogDebug("[Upgrade security] Cancelled security upgrade")
        MEGASdkManager.deleteSharedSdks()
        exit(0)
    }
}
