import Accounts
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

extension FileLinkViewController {
    @objc func download() {
        guard let publicLinkString = publicLinkString, let linkUrl = URL(string: publicLinkString) else { return }
        DownloadLinkRouter(link: linkUrl, isFolderLink: false, presenter: self).start()
    }
    
    @objc func showSendToChat() {
        if SAMKeychain.password(forService: "MEGA", account: "sessionV3") != nil {
            guard let sendToChatNavigationController =
                    UIStoryboard(
                        name: "Chat",
                        bundle: nil
                    ).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
                  let sendToViewController = sendToChatNavigationController.viewControllers.first as? SendToViewController else {
                return
            }
            
            sendToViewController.sendMode = .fileAndFolderLink
            self.sendLinkDelegate = SendLinkToChatsDelegate(link: linkEncryptedString ?? publicLinkString ?? "")
            sendToViewController.sendToViewControllerDelegate = self.sendLinkDelegate
            
            present(sendToChatNavigationController, animated: true)
            viewModel.dispatch(.trackSendToChatFileLink)
        } else {
            MEGALinkManager.linkSavedString = linkEncryptedString ?? publicLinkString ?? ""
            MEGALinkManager.selectedOption = .sendNodeLinkToChat

            navigationController?.pushViewController(
                OnboardingUSPViewController(), animated: true)
            viewModel.dispatch(.trackSendToChatFileLinkNoAccountLogged)
        }
    }
    
    @objc func showShareLink() {
        let link = linkEncryptedString ?? publicLinkString
        guard let link = link else { return }
        let activityVC = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = shareLinkBarButtonItem
        
        present(activityVC, animated: true)
    }
    
    @objc func present(decryption alertController: UIAlertController) {
        Task { @MainActor in
            self.present(alertController, animated: true) {
                self.decryptionAlertControllerHasBeenPresented = true
            }
        }
    }
    
    @objc func importFromFiles() {
        guard let node else { return }
        ImportLinkRouter(
            isFolderLink: false,
            nodes: [node],
            presenter: self).start()
    }
    
    @objc func configLiquidGlass() {
        if #available(iOS 26.0, *) {
            self.clearBackBarButton()
            edgesForExtendedLayout = .bottom
            extendedLayoutIncludesOpaqueBars = true
            setupButtonsLayoutForLandscape()
        }
    }

    private func setupButtonsLayoutForLandscape() {
        guard #available(iOS 26.0, *),
              let stackView = buttonsStackView,
              let parent = stackView.superview else { return }

        let landscapeConstraints = [
            stackView.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 16),
            parent.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 16)
        ]
        
        let importWidthConstraint = importButtonWidthConstraint
        let openWidthConstraint = openButtonWidthConstraint
        let bottomPaddingConstraint = buttonsBottomPaddingConstraint

        let apply: (FileLinkViewController) -> Void = { vc in
            let landscape = vc.traitCollection.verticalSizeClass == .compact
            stackView.axis = landscape ? .horizontal : .vertical
            stackView.distribution = landscape ? .fillEqually : .fill
            landscapeConstraints.forEach { $0.isActive = landscape }
            importWidthConstraint?.isActive = !landscape
            openWidthConstraint?.isActive = !landscape
            bottomPaddingConstraint?.isActive = !landscape
        }

        apply(self)
        registerForTraitChanges([UITraitVerticalSizeClass.self]) { (vc: FileLinkViewController, _) in
            apply(vc)
        }
    }
}

extension FileLinkViewController {
    @objc func configureViewModel() {
        viewModel = FileLinkViewModel()
    }
}

// MARK: - Ads
extension FileLinkViewController: AdsSlotViewControllerProtocol {
    public var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> {
        SingleItemAsyncSequence(
            item: AdsSlotConfig(displayAds: true)
        ).eraseToAnyAsyncSequence()
    }
}

// MARK: - hide action buttons
extension FileLinkViewController {
    @objc func hideActionButtons() {
        moreBarButtonItem?.isHidden = true
        navigationController?.isToolbarHidden = true
    }
}
