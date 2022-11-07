import MEGADomain

@objc final class SaveMediaToPhotosUseCaseOCWrapper: NSObject {
    @objc func saveToPhotos(node: MEGANode, isFolderLink: Bool = false) {
        let saveMediaUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: MEGASdkManager.sharedMEGASdk(), sharedFolderSdk: isFolderLink ? MEGASdkManager.sharedMEGASdkFolder() : nil), fileCacheRepository: FileCacheRepository.newRepo, nodeRepository: NodeRepository.newRepo)

        let completionBlock: (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void = { result in
            if case let .failure(error) = result, error != .cancelled {
                SVProgressHUD.dismiss()
                SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.somethingWentWrong)
            }
        }

        DevicePermissionsHelper.photosPermission { granted in
            if granted {
                TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
                saveMediaUseCase.saveToPhotos(node: node.toNodeEntity(), completion: completionBlock)
            } else {
                DevicePermissionsHelper.alertPhotosPermission()
            }
        }
    }
}
