import Accounts
import MEGADomain
import MEGASDKRepo
import MEGASwift

extension FileLinkViewController {
    @objc func download() {
        guard let publicLinkString = publicLinkString, let linkUrl = URL(string: publicLinkString) else { return }
        DownloadLinkRouter(link: linkUrl, isFolderLink: false, presenter: self).start()
    }

    @objc func showSendToChat() {
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
    }

    @objc func showShareLink() {
        let link = linkEncryptedString ?? publicLinkString
        guard let link = link else { return }
        let activityVC = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = shareLinkBarButtonItem

        present(activityVC, animated: true)
    }
    
    func addToCloudDrive() {
        self.node?.mnz_fileLinkImport(from: self, isFolderLink: false)
    }
}

// MARK: - Ads
extension FileLinkViewController: AdsSlotViewControllerProtocol {
    public var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> {
        SingleItemAsyncSequence(
            item: AdsSlotConfig(adsSlot: .sharedLink, displayAds: true)
        ).eraseToAnyAsyncSequence()
    }
}
