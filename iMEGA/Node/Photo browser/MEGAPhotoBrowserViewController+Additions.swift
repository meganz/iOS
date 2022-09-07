import UIKit
import MEGADomain

extension MEGAPhotoBrowserViewController {
    @objc func subtitle(fromDate date: Date) -> String {
        DateFormatter.fromTemplate("MMMM dd • HH:mm").localisedString(from: date)
    }
    
    @objc func freeUpSpace(onImageViewCache cache: NSCache<NSNumber, UIScrollView>, scrollView: UIScrollView) {
        SVProgressHUD.show()
        scrollView.subviews.forEach({ $0.removeFromSuperview() })
        cache.removeAllObjects()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SVProgressHUD.dismiss()
        }
    }
    
    @objc func rootPesentingViewController() -> UIViewController? {
        var curPresentingVC = presentingViewController
        var prePesentingVC: UIViewController?
        
        while curPresentingVC != nil {
            prePesentingVC = curPresentingVC
            curPresentingVC = curPresentingVC?.presentingViewController
        }
        
        return prePesentingVC
    }
    
    @objc func configureMediaAttachment(forMessageId messageId: HandleEntity, inChatId chatId: HandleEntity, messagesIds: [HandleEntity]) {
        self.chatId = chatId
        self.messageId = messageId
        self.messagesIds = messagesIds
    }
    
    @objc func saveToPhotos(node: MEGANode) {
        DevicePermissionsHelper.photosPermission { granted in
            if granted {
                let saveMediaUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: MEGASdkManager.sharedMEGASdk(), sharedFolderSdk: self.displayMode == .nodeInsideFolderLink ? self.api : nil), fileCacheRepository: FileCacheRepository.newRepo, nodeRepository: NodeRepository.newRepo)
                let completionBlock: (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void = { result in
                    if case let .failure(error) = result, error != .cancelled {
                        SVProgressHUD.dismiss()
                        SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.somethingWentWrong)
                    }
                }

                TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
                SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.savingToPhotos)

                switch self.displayMode {
                case .chatAttachment, .chatSharedFiles:
                    saveMediaUseCase.saveToPhotosChatNode(handle: node.handle, messageId: self.messageId, chatId: self.chatId, completion: completionBlock)
                case .fileLink:
                    guard let linkUrl = URL(string: self.publicLink) else { return }
                    let fileLink = FileLinkEntity(linkURL: linkUrl)
                    saveMediaUseCase.saveToPhotos(fileLink: fileLink, completion: completionBlock)
                default:
                    saveMediaUseCase.saveToPhotos(node: node.toNodeEntity(), completion: completionBlock)
                }
            } else {
                DevicePermissionsHelper.alertPhotosPermission()
            }
        }
    }
    
    @objc func downloadFileLink() {
        guard let linkUrl = URL(string: publicLink) else { return }
        DownloadLinkRouter(link: linkUrl, isFolderLink: false, presenter: self).start()
    }
    
    @objc func updateMessageId(to newIndex: UInt) {
        if messagesIds.isNotEmpty {
            guard let newMessageId = messagesIds[safe: Int(newIndex)] as? HandleEntity else { return }
            messageId = newMessageId
        }
    }

    @objc func openSlideShow() {
        SlideShowRouter(dataProvider: dataProvider, megaPhotoBrowserViewController: self).start()
    }
    
    @objc func isSlideShowEnabled() -> Bool {
        FeatureFlagProvider(useCase: FeatureFlagUseCase(repository: FeatureFlagRepository.newRepo)).isFeatureFlagEnabled(for: .slideShow) &&
        displayMode == .cloudDrive &&
        dataProvider.currentPhoto?.name?.mnz_isImagePathExtension == true
    }
    
    @objc func activateSlideShowButton() {
        if isSlideShowEnabled() {
            centerToolbarItem?.image = UIImage(systemName: "play.rectangle")
        } else {
            centerToolbarItem?.image = nil
        }
    }
    
    @objc func hideSlideShowButton() {
        centerToolbarItem?.image = nil
    }
}

extension MEGAPhotoBrowserViewController: MEGAPhotoBrowserPickerDelegate {
    public func updateCurrentIndex(to newIndex: UInt) {
        if dataProvider.shouldUpdateCurrentIndex(toIndex: Int(newIndex)) {
            dataProvider.currentIndex = Int(newIndex)
            needsReload = true
            updateMessageId(to: newIndex)
        }
    }
}

extension MEGAPhotoBrowserViewController {
    static func photoBrowser(currentPhoto: NodeEntity, allPhotos: [NodeEntity]) -> MEGAPhotoBrowserViewController {
        let sdk = MEGASdkManager.sharedMEGASdk()
        let browser = MEGAPhotoBrowserViewController.photoBrowser(
            with: PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: sdk),
            api: sdk,
            displayMode: .cloudDrive
        )
        browser.needsReload = true
        return browser
    }
}

extension MEGAPhotoBrowserViewController {
    @objc func updateProviderNodeEntities(nodes: [MEGANode]) {
        DispatchQueue.main.async {
            self.dataProvider.convertToNodeEntities(from: nodes)
        }
    }
}
