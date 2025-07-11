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
    private let isFolderLink: Bool
    
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
                downloadFileRepository: DownloadFileRepository(
                    sdk: MEGASdk.sharedSdk,
                    sharedFolderSdk: isFolderLink ? MEGASdk.sharedFolderLinkSdk : nil),
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
        self.isFolderLink = isFolderLink
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
    
    static func customProgressSVGErrorMessageDisplay(
        isFolderLink: Bool = false,
        configureProgress: @escaping () -> Void
    ) -> SaveToPhotosCoordinator {
        SaveToPhotosCoordinator(
            messageDisplay: CustomProgressSVGErrorMessageDisplay(
                configureProgress: configureProgress),
            isFolderLink: isFolderLink)
    }
}

struct CustomProgressSVGErrorMessageDisplay: SaveToPhotosMessageDisplay {
    private let configureProgress: (() -> Void)?
    
    init(configureProgress: (() -> Void)? = nil) {
        self.configureProgress = configureProgress
    }
    
    func showProgress() {
        configureProgress?()
    }
    
    func showError(_ error: any Error) {
        SVProgressHUD.dismiss()
        SVProgressHUD.show(
            MEGAAssets.UIImage.saveToPhotos,
            status: error.localizedDescription
        )
    }
}
