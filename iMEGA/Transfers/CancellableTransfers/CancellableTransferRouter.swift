
import Foundation

final class CancellableTransferRouter: NSObject, CancellableTransferRouting {
    
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
        let sdk = isFolderLink ? MEGASdkManager.sharedMEGASdkFolder() : MEGASdkManager.sharedMEGASdk()
        let nodeRepository = NodeRepository.default
        let fileSystemRepository = FileSystemRepository(fileManager: FileManager.default)
        
        let viewModel = CancellableTransferViewModel(
            router: self,
            uploadFileUseCase: UploadFileUseCase(uploadFileRepository: UploadFileRepository(sdk: sdk), fileSystemRepository: fileSystemRepository, nodeRepository: nodeRepository, fileCacheRepository: FileCacheRepository.default),
            downloadNodeUseCase: DownloadNodeUseCase(
                downloadFileRepository: DownloadFileRepository(sdk: sdk),
                offlineFilesRepository: OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: sdk),
                fileSystemRepository: fileSystemRepository,
                nodeRepository: nodeRepository,
                fileCacheRepository: FileCacheRepository.default),
            transfers: transfers,
            transferType: transferType)
        
        let wrapper = CancellableTransferControllerWrapper(viewModel: viewModel)
        self.wrapper = wrapper
        return wrapper.createViewController()
    }
    
    @objc func start() {
        guard let presenter = presenter else { return }
        presenter.present(build(), animated: true) { [weak self] in
            self?.wrapper?.hasBeenPresented()
        }
    }
    
    func transferSuccess(with message: String) {
        presenter?.dismiss(animated: true, completion: {
            SVProgressHUD.showSuccess(withStatus: message)
        })
    }
    
    func transferCancelled(with message: String) {
        presenter?.dismiss(animated: true, completion: {
            SVProgressHUD.showInfo(withStatus: message)
        })
    }
    
    func transferFailed(error: String) {
        presenter?.dismiss(animated: true, completion: {
            SVProgressHUD.showError(withStatus: error)
        })
    }
    
    func transferCompletedWithError(error: String) {
        presenter?.dismiss(animated: true, completion: {
            SVProgressHUD.show(Asset.Images.Hud.hudDownload.image, status: error)
        })
    }
    
    func showConfirmCancel() {
        guard let wrapper = wrapper else {
            return
        }
        presenter?.dismiss(animated: true, completion: {
            self.presenter?.present(wrapper.confirmCancelAlertController(), animated: true)
        })
    }
    
    func dismissConfirmCancel() {
        guard let wrapper = wrapper else {
            return
        }
        presenter?.dismiss(animated: true, completion: {
            self.presenter?.present(wrapper.cancelAlertController(), animated: true)
        })
    }
}
