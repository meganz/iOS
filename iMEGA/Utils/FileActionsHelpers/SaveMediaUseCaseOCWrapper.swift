
@objc final class SaveMediaToPhotosUseCaseOCWrapper: NSObject {
    
    private let completionBlock: (SaveMediaToPhotosErrorEntity?) -> Void = { error in
        SVProgressHUD.dismiss()

        if error != nil {
            SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.somethingWentWrong)
        }
    }
    
    let saveMediaUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: MEGASdkManager.sharedMEGASdk()), fileCacheRepository: FileCacheRepository.default, nodeRepository: NodeRepository(sdk: MEGASdkManager.sharedMEGASdk()))
    
    @objc func saveToPhotos(node: MEGANode, cancelToken: MEGACancelToken) {
        DevicePermissionsHelper.photosPermission { granted in
            if granted {
                TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
                SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.savingToPhotos)
                let nodeEntity = NodeEntity(node: node)
                self.saveMediaUseCase.saveToPhotos(node: nodeEntity, cancelToken: cancelToken, completion: self.completionBlock)
            } else {
                DevicePermissionsHelper.alertPhotosPermission()
            }
        }
    }
}
