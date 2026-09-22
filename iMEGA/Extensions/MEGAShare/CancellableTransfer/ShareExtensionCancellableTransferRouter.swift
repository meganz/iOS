import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGARepo
import UIKit

final class ShareExtensionCancellableTransferRouter: NSObject, CancellableTransferRouting {
    
    private weak var presenter: UIViewController?
    
    private let transfers: [CancellableTransfer]
    private var wrapper: CancellableTransferControllerWrapper<ShareExtensionCancellableTransferViewModel>?

    init(presenter: UIViewController, transfers: [CancellableTransfer]) {
        self.presenter = presenter
        self.transfers = transfers
    }
    
    func build() -> UIViewController {
        let sdk = MEGASdk.shared
        let nodeRepository = NodeRepository.newRepo
        let fileSystemRepository = FileSystemRepository.sharedRepo
        
        let viewModel =  ShareExtensionCancellableTransferViewModel(router: self, uploadFileUseCase: UploadFileUseCase(uploadFileRepository: UploadFileRepository(sdk: sdk), fileSystemRepository: fileSystemRepository, nodeRepository: nodeRepository, fileCacheRepository: FileCacheRepository.newRepo), transfers: transfers)
        
        return install(CancellableTransferControllerWrapper(viewModel: viewModel))
    }
    
    // Dependency-injection seam used by tests to avoid constructing app-wide repositories.
    func build(viewModel: ShareExtensionCancellableTransferViewModel) -> UIViewController {
        install(CancellableTransferControllerWrapper(viewModel: viewModel))
    }
    
    private func install(_ wrapper: CancellableTransferControllerWrapper<ShareExtensionCancellableTransferViewModel>) -> UIViewController {
        self.wrapper = wrapper
        return wrapper.createViewController()
    }
    
    @objc func start() {
        _ = build()
        wrapper?.viewIsReady()
    }
    
    func showTransfersAlert() {
        // Reuse the wrapper built in `start()`. Building again replaces it, and the alert on
        // screen only holds it weakly, so its Cancel button would dispatch nothing.
        guard let presenter, let alert = wrapper?.cancelAlertController() else { return }
        presenter.present(alert, animated: true)
    }
    
    func transferSuccess(with message: String, dismiss: Bool) {
        if dismiss {
            presenter?.dismiss(animated: true, completion: {
                SVProgressHUD.showSuccess(withStatus: message)
                self.finishShareExtensionIfNeeded()
            })
        } else {
            SVProgressHUD.showSuccess(withStatus: message)
            self.finishShareExtensionIfNeeded()
        }
    }
    
    func transferCancelled(with message: String, dismiss: Bool) {
        if dismiss {
            presenter?.dismiss(animated: true, completion: {
                SVProgressHUD.showInfo(withStatus: message)
                self.finishShareExtensionIfNeeded()
            })
        } else {
            SVProgressHUD.showInfo(withStatus: message)
            self.finishShareExtensionIfNeeded()
        }
    }
    
    func transferFailed(error: String, dismiss: Bool) {
        if dismiss {
            presenter?.dismiss(animated: true, completion: {
                SVProgressHUD.showError(withStatus: error)
                self.finishShareExtensionIfNeeded()
            })
        } else {
            SVProgressHUD.showError(withStatus: error)
            self.finishShareExtensionIfNeeded()
        }
    }
    
    func transferCompletedWithError(error: String, dismiss: Bool) {
        if dismiss {
            presenter?.dismiss(animated: true, completion: {
                SVProgressHUD.show(MEGAAssets.UIImage.hudDownload, status: error)
                self.finishShareExtensionIfNeeded()
            })
        } else {
            SVProgressHUD.show(MEGAAssets.UIImage.hudDownload, status: error)
            self.finishShareExtensionIfNeeded()
        }
    }
    
    private func finishShareExtensionIfNeeded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.presenter?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
