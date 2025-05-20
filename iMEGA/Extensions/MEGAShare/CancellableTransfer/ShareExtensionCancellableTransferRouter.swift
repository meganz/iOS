import MEGAAppSDKRepo
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
        
        let wrapper = CancellableTransferControllerWrapper(viewModel: viewModel)
        self.wrapper = wrapper
        return wrapper.createViewController()
    }
    
    @objc func start() {
        guard let presenter = presenter else { return }
        presenter.present(build(), animated: true) { [weak self] in
            self?.wrapper?.viewIsReady()
        }
    }
    
    func showTransfersAlert() {
        guard let presenter = presenter else { return }
        presenter.present(build(), animated: true)
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
                SVProgressHUD.show(UIImage.hudDownload, status: error)
                self.finishShareExtensionIfNeeded()
            })
        } else {
            SVProgressHUD.show(UIImage.hudDownload, status: error)
            self.finishShareExtensionIfNeeded()
        }
    }
    
    private func finishShareExtensionIfNeeded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.presenter?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
