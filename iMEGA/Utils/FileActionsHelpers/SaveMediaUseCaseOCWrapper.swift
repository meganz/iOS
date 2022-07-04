
@objc final class SaveMediaToPhotosUseCaseOCWrapper: NSObject {
    @objc func saveToPhotos(node: MEGANode, isFolderLink: Bool = false) {
        let sdk = isFolderLink ? MEGASdkManager.sharedMEGASdkFolder() : MEGASdkManager.sharedMEGASdk()
        
        let saveMediaUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: sdk), fileCacheRepository: FileCacheRepository.default, nodeRepository: NodeRepository.default)

        let completionBlock: (SaveMediaToPhotosErrorEntity?) -> Void = { error in
            SVProgressHUD.dismiss()

            if error != nil {
                SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.somethingWentWrong)
            }
        }
        
        DevicePermissionsHelper.photosPermission { granted in
            if granted {
                TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
                SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.savingToPhotos)
                let nodeEntity = NodeEntity(node: node)
                saveMediaUseCase.saveToPhotos(node: nodeEntity, completion: completionBlock)
            } else {
                DevicePermissionsHelper.alertPhotosPermission()
            }
        }
    }
}
