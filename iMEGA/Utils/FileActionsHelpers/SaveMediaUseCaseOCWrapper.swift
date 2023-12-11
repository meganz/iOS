import ChatRepo
import MEGADomain
import MEGAPermissions
import MEGASDKRepo

@objc final class SaveMediaToPhotosUseCaseOCWrapper: NSObject {
    @objc func saveToPhotos(node: MEGANode, isFolderLink: Bool = false) {
        let saveMediaUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: MEGASdk.sharedSdk, sharedFolderSdk: isFolderLink ? MEGASdk.sharedFolderLinkSdk : nil), fileCacheRepository: FileCacheRepository.newRepo, nodeRepository: NodeRepository.newRepo, chatNodeRepository: ChatNodeRepository.newRepo, downloadChatRepository: DownloadChatRepository.newRepo)
        let permissionHandler = DevicePermissionsHandler.makeHandler()
        
        permissionHandler.photosPermissionWithCompletionHandler { granted in
            if granted {
                TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
                Task { @MainActor in
                    do {
                        try await saveMediaUseCase.saveToPhotos(nodes: [node.toNodeEntity()])
                    } catch {
                        if let errorEntity = error as? SaveMediaToPhotosErrorEntity, errorEntity != .cancelled {
                            await SVProgressHUD.dismiss()
                            SVProgressHUD.show(
                                UIImage.saveToPhotos,
                                status: error.localizedDescription
                            )
                        }
                    }
                }
            } else {
                PermissionAlertRouter
                    .makeRouter(deviceHandler: permissionHandler)
                    .alertPhotosPermission()
            }
        }
    }
}
