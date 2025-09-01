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
            guard let navigationController =
                    UIStoryboard(
                        name: "Chat",
                        bundle: nil
                    ).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
                  let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
                return
            }
            
            sendToViewController.sendMode = .fileAndFolderLink
            self.sendLinkDelegate = SendLinkToChatsDelegate(
                link: linkEncryptedString ?? publicLinkString ?? "",
                navigationController: navigationController
            )
            sendToViewController.sendToViewControllerDelegate = self.sendLinkDelegate
            
            self.navigationController?.pushViewController(sendToViewController, animated: true)
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
