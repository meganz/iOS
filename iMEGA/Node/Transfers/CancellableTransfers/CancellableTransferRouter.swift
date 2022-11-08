
import Foundation
import MEGADomain

final class CancellableTransferRouter: NSObject, CancellableTransferRouting, TransferWidgetRouting {
    
    private weak var presenter: UIViewController?
    
    private let transfers: [CancellableTransfer]
    private let transferType: CancellableTransferType
    private let isFolderLink: Bool
    private var wrapper: CancellableTransferControllerWrapper<CancellableTransferViewModel>?

    init(presenter: UIViewController, transfers: [CancellableTransfer], transferType: CancellableTransferType, isFolderLink: Bool = false) {
        self.presenter = presenter
        self.transfers = transfers
        self.transferType = transferType
        self.isFolderLink = isFolderLink
    }
    
    func build() -> UIViewController {
        let sdk = MEGASdkManager.sharedMEGASdk()
        let nodeRepository = NodeRepository.newRepo
        let fileSystemRepository = FileSystemRepository(fileManager: FileManager.default)
        
        let viewModel = CancellableTransferViewModel(
            router: self,
            uploadFileUseCase: UploadFileUseCase(uploadFileRepository: UploadFileRepository(sdk: sdk), fileSystemRepository: fileSystemRepository, nodeRepository: nodeRepository, fileCacheRepository: FileCacheRepository.newRepo),
            downloadNodeUseCase: DownloadNodeUseCase(
                downloadFileRepository: DownloadFileRepository(sdk: sdk, sharedFolderSdk: isFolderLink ? MEGASdkManager.sharedMEGASdkFolder() : nil),
                offlineFilesRepository: OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: sdk),
                fileSystemRepository: fileSystemRepository,
                nodeRepository: nodeRepository,
                nodeDataRepository: NodeDataRepository.newRepo,
                fileCacheRepository: FileCacheRepository.newRepo,
                mediaUseCase: MediaUseCase(),
                preferenceRepository: PreferenceRepository.newRepo),
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
        guard let presenter = presenter, let wrapper = wrapper?.cancelAlertController() else { return }
        presenter.present(wrapper, animated: true)
    }
    
    func transferSuccess(with message: String, dismiss: Bool) {
        if dismiss {
            presenter?.dismiss(animated: true, completion: {
                SVProgressHUD.showSuccess(withStatus: message)
            })
        } else {
            SVProgressHUD.showSuccess(withStatus: message)
        }
    }
    
    func transferCancelled(with message: String, dismiss: Bool) {
        if dismiss {
            presenter?.dismiss(animated: true, completion: {
                SVProgressHUD.showInfo(withStatus: message)
            })
        } else {
            SVProgressHUD.showInfo(withStatus: message)
        }
    }
    
    func transferFailed(error: String, dismiss: Bool) {
        if dismiss {
            presenter?.dismiss(animated: true, completion: {
                SVProgressHUD.showError(withStatus: error)
            })
        } else {
            SVProgressHUD.showError(withStatus: error)
        }
    }
    
    func transferCompletedWithError(error: String, dismiss: Bool) {
        if dismiss {
            presenter?.dismiss(animated: true, completion: {
                SVProgressHUD.show(Asset.Images.Hud.hudDownload.image, status: error)
            })
        }else {
            SVProgressHUD.show(Asset.Images.Hud.hudDownload.image, status: error)
        }
    }
    
    func prepareTransfersWidget() {
        TransfersWidgetViewController.sharedTransfer().setProgressViewInKeyWindow()
        TransfersWidgetViewController.sharedTransfer().progressView?.showWidgetIfNeeded()
        TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
    }
}
