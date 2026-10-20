import ChatRepo
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAPermissions
import MEGAPreference

@MainActor
protocol SaveToPhotosMessageDisplay {
    func showProgress()
    func showError(_ error: any Error)
}

@MainActor
final class SaveToPhotosCoordinator: SaveToPhotosCoordinatorProtocol {
    private let messageDisplay: any SaveToPhotosMessageDisplay
    private let downloadFileRepository: DownloadFileRepository
    
    private lazy var permissionHandler = DevicePermissionsHandler.makeHandler()
    private lazy var viewModel: SaveToPhotosViewModel = {
        SaveToPhotosViewModel(
            coordinator: self,
            overDiskQuotaChecker: OverDiskQuotaChecker(
                accountStorageUseCase: AccountStorageUseCase(
                    accountRepository: AccountRepository.newRepo,
                    preferenceUseCase: PreferenceUseCase.default
                ),
                appDelegateRouter: AppDelegateRouter()),
            devicePermissionsHandling: permissionHandler,
            saveMediaToPhotosUseCase: SaveMediaToPhotosUseCase(
                downloadFileRepository: downloadFileRepository,
                fileCacheRepository: FileCacheRepository.newRepo,
                nodeRepository: NodeRepository.newRepo,
                chatNodeRepository: ChatNodeRepository.newRepo,
                downloadChatRepository: DownloadChatRepository.newRepo
            ))
    }()
    
    init(
        messageDisplay: some SaveToPhotosMessageDisplay,
        isFolderLink: Bool
    ) {
        self.messageDisplay = messageDisplay
        self.downloadFileRepository = DownloadFileRepository(
            sdk: MEGASdk.sharedSdk,
            sharedFolderSdk: isFolderLink ? MEGASdk.sharedFolderLinkSdk : nil,
            chatNodeProvider: ChatMEGANodeProvider(chatSdk: MEGAChatSdk.sharedChatSdk, sdk: MEGASdk.shared)
        )
    }

    init(
        messageDisplay: some SaveToPhotosMessageDisplay,
        isFolderLink: Bool,
        nodeProvider: some MEGANodeProviderProtocol
    ) {
        self.messageDisplay = messageDisplay
        self.downloadFileRepository = DownloadFileRepository(
            sdk: MEGASdk.sharedSdk,
            sharedFolderSdk: isFolderLink ? MEGASdk.sharedFolderLinkSdk : nil,
            nodeProvider: nodeProvider,
            chatNodeProvider: ChatMEGANodeProvider(chatSdk: MEGAChatSdk.sharedChatSdk, sdk: MEGASdk.shared)
        )
    }
    
    func saveToPhotos(nodes: [NodeEntity], onComplete: (() -> Void)? = nil) {
        Task {
            await viewModel.saveToPhotos(nodes: nodes)
            onComplete?()
        }
    }
    
    func saveToPhotos(fileLink: FileLinkEntity, onComplete: (() -> Void)? = nil) {
        Task {
            await viewModel.saveToPhotos(fileLink: fileLink)
            onComplete?()
        }
    }
    
    func saveToPhotosChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity, onComplete: (() -> Void)? = nil) {
        Task {
            await viewModel.saveToPhotosChatNode(
                handle: handle, messageId: messageId, chatId: chatId)
            onComplete?()
        }
    }
    
    func showPhotoPermissionAlert() {
        PermissionAlertRouter.makeRouter(deviceHandler: permissionHandler)
            .alertPhotosPermission()
    }
    
    func showProgress() {
        messageDisplay.showProgress()
    }
    
    func showError(_ error: any Error) {
        messageDisplay.showError(error)
    }
}

extension SaveToPhotosCoordinator {
    static func SVProgressErrorOnly(
        isFolderLink: Bool = false
    ) -> SaveToPhotosCoordinator {
        SaveToPhotosCoordinator(
            messageDisplay: CustomProgressSVGErrorMessageDisplay(),
            isFolderLink: isFolderLink)
    }
}

struct CustomProgressSVGErrorMessageDisplay: SaveToPhotosMessageDisplay {
    func showProgress() {}
    
    func showError(_ error: any Error) {
        SVProgressHUD.dismiss()
        SVProgressHUD.show(
            MEGAAssets.UIImage.saveToPhotos,
            status: error.localizedDescription
        )
    }
}
