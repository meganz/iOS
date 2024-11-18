import Accounts
import Combine
import MEGADomain
import MEGASDKRepo

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
    public var adsSlotPublisher: AnyPublisher<AdsSlotConfig?, Never> {
        Just(
            AdsSlotConfig(
                adsSlot: .sharedLink,
                displayAds: true,
                isAdsCookieEnabled: calculateAdCookieStatus
            )
        ).eraseToAnyPublisher()
    }
    
    private func calculateAdCookieStatus() async -> Bool {
        do {
            let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository.newRepo)
            let bitmap = try await cookieSettingsUseCase.cookieSettings()
            
            let cookiesBitmap = CookiesBitmap(rawValue: bitmap)
            return cookiesBitmap.contains(.ads) && cookiesBitmap.contains(.adsCheckCookie)
        } catch {
            return false
        }
    }
}
