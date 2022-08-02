import UIKit

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
                let completionBlock: (SaveMediaToPhotosErrorEntity?) -> Void = { error in
                    SVProgressHUD.dismiss()
                    
                    if error != nil {
                        SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.somethingWentWrong)
                    }
                }

                TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
                SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.savingToPhotos)

                switch self.displayMode {
                case .chatAttachment, .chatSharedFiles:
                    saveMediaUseCase.saveToPhotosChatNode(handle: node.handle, messageId: self.messageId, chatId: self.chatId, completion: completionBlock)
                case .fileLink:
                    Task {
                        do {
                            guard let linkUrl = URL(string: self.publicLink) else { return }
                            let fileLink = FileLinkEntity(linkURL: linkUrl)
                            try await saveMediaUseCase.saveToPhotos(fileLink: fileLink)
                        } catch {
                            MEGALogDebug("Failed to saveToPhotosFileLink \(error)")
                            SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.somethingWentWrong)
                        }
                    }
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
