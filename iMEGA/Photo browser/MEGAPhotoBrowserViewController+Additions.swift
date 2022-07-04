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
    
    @objc func configureMediaAttachment(forMessageId messageId: MEGAHandle, inChatId chatId: MEGAHandle) {
        self.chatId = chatId
        self.messageId = messageId
    }
    
    @objc func saveToPhotos(node: MEGANode) {
        DevicePermissionsHelper.photosPermission { granted in
            if granted {
                let saveMediaUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: MEGASdkManager.sharedMEGASdk()), fileCacheRepository: FileCacheRepository.newRepo, nodeRepository: NodeRepository.newRepo)
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
                    saveMediaUseCase.saveToPhotosMEGANode(node: node, completion: completionBlock)
                default:
                    saveMediaUseCase.saveToPhotos(node: NodeEntity(node: node), completion: completionBlock)
                }
            } else {
                DevicePermissionsHelper.alertPhotosPermission()
            }
        }
    }
}
