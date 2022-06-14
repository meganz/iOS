
import UIKit

final class CancellableTransferControllerWrapper<U: ViewModelType>: NSObject {
    private var viewModel: U
    private var cancelTransferAlertController = UIAlertController(
        title: Strings.Localizable.Transfers.Cancellable.scanning,
        message: Strings.Localizable.Transfers.Cancellable.donotclose,
        preferredStyle: .alert)
    
    let transferProgress : UIProgressView = UIProgressView(progressViewStyle: .default)

    init(viewModel: U) {
        self.viewModel = viewModel
        super.init()
    }
    
    func createViewController() -> UIViewController {
        createAlertController()
    }

    func hasBeenPresented() {
        guard let onViewReady = CancellableTransferViewAction.onViewReady as? U.Action else { return }
        viewModel.dispatch(onViewReady)
    }
    
    private func createAlertController() -> UIAlertController {
        viewModel.invokeCommand = { [weak self] in
            guard let command = $0 as? Command else { return }
            self?.executeCommand(command)
        }
        
        transferProgress.frame = CGRect(x: 8.0, y: 90.0, width: 244.0, height: 8.0)
        transferProgress.tintColor = #colorLiteral(red: 0, green: 0.6588235294, blue: 0.5254901961, alpha: 1)
        transferProgress.progress = 0.25
        cancelTransferAlertController.view.addSubview(transferProgress)

        cancelTransferAlertController.addAction(UIAlertAction(title: Strings.Localizable.Transfers.Cancellable.cancel, style: .cancel) { _ in
            self.viewModel.dispatch(CancellableTransferViewAction.didTapCancelButton as! U.Action)
        })

        return cancelTransferAlertController
    }
    
    func cancelAlertController() -> UIAlertController {
        cancelTransferAlertController
    }
    
    func confirmCancelAlertController() -> UIAlertController {
        let confirmCancelAlertController = UIAlertController(
            title: Strings.Localizable.Transfers.Cancellable.title,
            message: Strings.Localizable.Transfers.Cancellable.cancel,
            preferredStyle: .alert)
        
        confirmCancelAlertController.addAction(UIAlertAction(title: Strings.Localizable.Transfers.Cancellable.dismiss, style: .default) { _ in
            self.viewModel.dispatch(CancellableTransferViewAction.didTapDismissConfirmCancel as! U.Action)
        })
        confirmCancelAlertController.addAction(UIAlertAction(title: Strings.Localizable.Transfers.Cancellable.proceed, style: .default) { _ in
            self.viewModel.dispatch(CancellableTransferViewAction.didTapProceedCancel as! U.Action)
        })
        
        return confirmCancelAlertController
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: Command) {
        switch command {
        case .confirmCancel:
            cancelTransferAlertController.title = Strings.Localizable.Transfers.Cancellable.cancel
            cancelTransferAlertController.message = Strings.Localizable.Transfers.Cancellable.confirmCancel
        }
    }
}
