import ChatRepo
import Foundation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAPreference
import MEGARepo

@MainActor
final class CancellableTransferRouter: NSObject, CancellableTransferRouting, TransferWidgetRouting {
    
    @MainActor
    struct Factory {
        let presenter: UIViewController
        let node: MEGANode
        let transfers: [CancellableTransfer]
        let isNodeFromFolderLink: Bool
        let messageId: HandleEntity?
        let chatId: HandleEntity?
        
        func make() -> CancellableTransferRouter {
            let transferType: () -> CancellableTransferType = {
                if let messageId = messageId, let chatId = chatId, messageId != .invalid || chatId != .invalid {
                    return .downloadChat
                } else {
                    return .download
                }
            }

            return .init(
                presenter: presenter,
                transfers: transfers,
                transferType: transferType(),
                isFolderLink: isNodeFromFolderLink
            )

        }
    }
    
    private weak var presenter: UIViewController?
    
    private(set) var transfers: [CancellableTransfer]
    private(set) var transferType: CancellableTransferType
    private(set) var isFolderLink: Bool
    private let preresolvedNodes: [HandleEntity: MEGANode]
    private var wrapper: CancellableTransferControllerWrapper<CancellableTransferViewModel>?
    private weak var presentedAlert: UIAlertController?

    /// - Parameter preresolvedNodes: The transfers' nodes, for a source that cannot look them up in any
    ///   SDK tree -- a public album link's photos come from a set preview, and its own screen is what
    ///   resolves them. Left out, the download looks its nodes up in the account tree as usual.
    init(presenter: UIViewController,
         transfers: [CancellableTransfer],
         transferType: CancellableTransferType,
         isFolderLink: Bool = false,
         preresolvedNodes: [HandleEntity: MEGANode] = [:]) {
        self.presenter = presenter
        self.transfers = transfers
        self.transferType = transferType
        self.isFolderLink = isFolderLink
        self.preresolvedNodes = preresolvedNodes
    }
    
    private func makeDownloadFileRepository(sdk: MEGASdk) -> DownloadFileRepository {
        DownloadFileRepository(sdk: sdk,
                               sharedFolderSdk: isFolderLink ? .sharedFolderLink : nil,
                               preresolvedNodes: preresolvedNodes)
    }
    
    func build() -> UIViewController {
        let sdk = MEGASdk.shared
        let nodeRepository = NodeRepository.newRepo
        let fileSystemRepository = FileSystemRepository.sharedRepo
        let overDiskQuotaChecker = OverDiskQuotaChecker(
            accountStorageUseCase: AccountStorageUseCase(
                accountRepository: AccountRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default),
            appDelegateRouter: AppDelegateRouter())
        
        let viewModel = CancellableTransferViewModel(
            router: self,
            uploadFileUseCase: UploadFileUseCase(uploadFileRepository: UploadFileRepository(sdk: sdk), fileSystemRepository: fileSystemRepository, nodeRepository: nodeRepository, fileCacheRepository: FileCacheRepository.newRepo),
            downloadNodeUseCase: DownloadNodeUseCase(
                downloadFileRepository: makeDownloadFileRepository(sdk: sdk),
                offlineFilesRepository: OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: sdk, folderSizeCalculator: FolderSizeCalculator()),
                fileSystemRepository: fileSystemRepository,
                nodeRepository: nodeRepository,
                nodeDataRepository: NodeDataRepository.newRepo,
                fileCacheRepository: FileCacheRepository.newRepo,
                mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
                preferenceRepository: PreferenceRepository.newRepo,
                offlineFileFetcherRepository: OfflineFileFetcherRepository.newRepo,
                chatNodeRepository: ChatNodeRepository.newRepo,
                downloadChatRepository: DownloadChatRepository.newRepo), 
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            analyticsEventUseCase: AnalyticsEventUseCase(repository: AnalyticsRepository.newRepo),
            overDiskQuotaChecker: overDiskQuotaChecker,
            transfers: transfers,
            transferType: transferType)
        
        let wrapper = CancellableTransferControllerWrapper(viewModel: viewModel)
        self.wrapper = wrapper
        return wrapper.createViewController()
    }
    
    @objc func start() {
        _ = build()
        wrapper?.viewIsReady()
    }
    
    func showTransfersAlert() {
        guard let presenter = presenter, let alert = wrapper?.cancelAlertController() else { return }
        presentedAlert = alert
        presenter.present(alert, animated: true)
    }
    
    /// Whether `presenter?.dismiss()` would close this router's own cancel-transfer alert.
    private var canDismissTransfersAlert: Bool {
        guard let presented = presenter?.presentedViewController, presented === presentedAlert else {
            return false
        }
        return presented.presentedViewController == nil
    }
    
    func transferSuccess(with message: String, dismiss: Bool) {
        if dismiss, canDismissTransfersAlert {
            presenter?.dismiss(animated: true)
        }
    }
    
    func transferCancelled(with message: String, dismiss: Bool) {
        if dismiss, canDismissTransfersAlert {
            presenter?.dismiss(animated: true, completion: {
                SVProgressHUD.showInfo(withStatus: message)
            })
        } else {
            SVProgressHUD.showInfo(withStatus: message)
        }
    }
    
    func transferFailed(error: String, dismiss: Bool) {
        if dismiss, canDismissTransfersAlert {
            presenter?.dismiss(animated: true, completion: {
                SVProgressHUD.showError(withStatus: error)
            })
        } else {
            SVProgressHUD.showError(withStatus: error)
        }
    }
    
    func transferCompletedWithError(error: String, dismiss: Bool) {
        if dismiss, canDismissTransfersAlert {
            presenter?.dismiss(animated: true, completion: {
                SVProgressHUD.show(MEGAAssets.UIImage.hudDownload, status: error)
            })
        } else {
            SVProgressHUD.show(MEGAAssets.UIImage.hudDownload, status: error)
        }
    }
    
    func prepareTransfersWidget() {
        TransfersWidgetViewController.sharedTransfer().setProgressViewInKeyWindow()
        TransfersWidgetViewController.sharedTransfer().progressView?.showWidgetIfNeeded()
        TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
    }
}
