import UIKit
import MEGADomain

extension MEGAPhotoBrowserViewController {
    @objc func createNodeInfoViewModel(withNode node: MEGANode) -> NodeInfoViewModel {
        NodeInfoViewModel(withNode: node)
    }
    
    @objc func subtitle(fromDate date: Date) -> String {
        DateFormatter.fromTemplate("MMMM dd • HH:mm").localisedString(from: date)
    }
    
    @objc func freeUpSpace(
        onImageViewCache cache: NSCache<NSNumber, UIScrollView>,
        imageViewsZoomCache: NSCache<NSNumber, NSNumber>,
        scrollView: UIScrollView
    ) {
        SVProgressHUD.show()
        scrollView.subviews.forEach({ $0.removeFromSuperview() })
        cache.removeAllObjects()
        imageViewsZoomCache.removeAllObjects()
        
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
                        SVProgressHUD.show(
                            Asset.Images.NodeActions.saveToPhotos.image,
                            status: error.localizedDescription
                        )
                    }
                }

                TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()

                switch self.displayMode {
                case .chatAttachment, .chatSharedFiles:
                    saveMediaUseCase.saveToPhotosChatNode(handle: node.handle, messageId: self.messageId, chatId: self.chatId, completion: completionBlock)
                case .fileLink:
                    guard let linkUrl = URL(string: self.publicLink) else { return }
                    let fileLink = FileLinkEntity(linkURL: linkUrl)
                    saveMediaUseCase.saveToPhotos(fileLink: fileLink, completion: completionBlock)
                default:
                    Task { @MainActor in
                        do {
                            try await saveMediaUseCase.saveToPhotos(nodes: [node.toNodeEntity()])
                        } catch {
                            if let errorEntity = error as? SaveMediaToPhotosErrorEntity, errorEntity != .cancelled {
                                await SVProgressHUD.dismiss()
                                SVProgressHUD.show(
                                    Asset.Images.NodeActions.saveToPhotos.image,
                                    status: error.localizedDescription
                                )
                            }
                        }
                    }
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
        SlideShowRouter(dataProvider: dataProvider, presenter: self).start()
    }
    
    @objc func isSlideShowEnabled() -> Bool {
        (displayMode == .cloudDrive || displayMode == .sharedItem) &&
        dataProvider.currentPhoto?.name?.mnz_isImagePathExtension == true
    }
    
    @objc func activateSlideShowButton() {
        if isSlideShowEnabled() {
            centerToolbarItem?.image = UIImage(systemName: "play.rectangle")
            centerToolbarItem?.isEnabled = true
        } else {
            centerToolbarItem?.image = nil
            centerToolbarItem?.isEnabled = false
        }
    }
    
    @objc func hideSlideShowButton() {
        centerToolbarItem?.image = nil
        centerToolbarItem?.isEnabled = false
    }
    
    @objc func viewNodeInFolder(_ node: MEGANode) {
        guard let parentNode = MEGASdkManager.sharedMEGASdk().node(forHandle: node.parentHandle),
              parentNode.isFolder() else {
            return
        }
        openFolderNode(parentNode, isFromViewInFolder: true)
    }
    
    func openFolderNode(_ node: MEGANode, isFromViewInFolder: Bool) {
        let cloudStoryboard = UIStoryboard(name: "Cloud", bundle: nil)
        guard let cloudDriveViewController = cloudStoryboard.instantiateViewController(withIdentifier: "CloudDriveID") as? CloudDriveViewController else { return }
        cloudDriveViewController.parentNode = node
        cloudDriveViewController.isFromViewInFolder = isFromViewInFolder
        
        if node.mnz_isInRubbishBin() && isFromViewInFolder {
            cloudDriveViewController.displayMode = .rubbishBin
        }
        
        let navigationContorller = MEGANavigationController(rootViewController: cloudDriveViewController)
        present(navigationContorller, animated: true)
    }
    
    @objc func clearNodeOnTransfers(_ node: MEGANode) {
        if let navController = presentingViewController as? MEGANavigationController,
           let transfersController = navController.viewControllers.last as? TransfersWidgetViewController {
            transfersController.clear(node)
        } else if let tabBarController = presentingViewController as? MainTabBarController,
                  let navController = tabBarController.selectedViewController as? MEGANavigationController,
                  let transfersController = navController.viewControllers.last as? TransfersWidgetViewController {
            transfersController.clear(node)
        }
    }
    
    @objc func showRemoveLinkWarning(_ node: MEGANode) {
        ActionWarningViewRouter(presenter: self, nodes: [node.toNodeEntity()], actionType: .removeLink, onActionStart: {
            SVProgressHUD.show()
        }, onActionFinish: {
            switch $0 {
            case .success(let message):
                SVProgressHUD.showSuccess(withStatus: message)
            case .failure:
                SVProgressHUD.dismiss()
            }
        }).start()
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
