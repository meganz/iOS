import MEGAL10n
import MEGAPresentation
import UIKit

@MainActor
final class CancellableTransferControllerWrapper<U: ViewModelType>: NSObject {
    private var viewModel: U
    private var cancelTransferAlertController = UIAlertController(
        title: Strings.Localizable.Transfers.Cancellable.scanning,
        message: Strings.Localizable.Transfers.Cancellable.donotclose,
        preferredStyle: .alert)
    
    init(viewModel: U) {
        self.viewModel = viewModel
        super.init()
    }
    
    func createViewController() -> UIViewController {
        createAlertController()
    }

    func viewIsReady() {
        guard let onViewReady = CancellableTransferViewAction.onViewReady as? U.Action else { return }
        viewModel.dispatch(onViewReady)
    }
    
    private func createAlertController() -> UIAlertController {
        viewModel.invokeCommand = { [weak self] in
            guard let command = $0 as? Command else { return }
            self?.executeCommand(command)
        }

        cancelTransferAlertController.addAction(UIAlertAction(title: Strings.Localizable.Transfers.Cancellable.cancel, style: .cancel) { _ in
            self.viewModel.dispatch(CancellableTransferViewAction.didTapCancelButton as! U.Action)
        })

        return cancelTransferAlertController
    }
    
    func cancelAlertController() -> UIAlertController {
        cancelTransferAlertController
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: Command) {
        switch command {
        case .scanning(let name, let folders, let files):
            self.cancelTransferAlertController.title = Strings.Localizable.Transfers.Cancellable.scanning
            self.cancelTransferAlertController.message = name + "\n" + Strings.Localizable.Transfers.Cancellable.Scanning.count(Strings.Localizable.General.Format.Count.folder(Int(folders)), Strings.Localizable.General.Format.Count.file(Int(files))) + "\n" + Strings.Localizable.Transfers.Cancellable.donotclose
        case .creatingFolders(let createdFolders, let totalFolders):
            self.cancelTransferAlertController.title = Strings.Localizable.Transfers.Cancellable.creatingFolders
            self.cancelTransferAlertController.message = Strings.Localizable.Transfers.Cancellable.CreatingFolders.count(createdFolders, Strings.Localizable.General.Format.Count.folder(Int(totalFolders))) + "\n" + Strings.Localizable.Transfers.Cancellable.donotclose
        case .transferring:
            self.cancelTransferAlertController.title = Strings.Localizable.Transfers.Cancellable.transferring
            self.cancelTransferAlertController.message = Strings.Localizable.Transfers.Cancellable.donotclose
        case .cancelling:
            self.cancelTransferAlertController.title = Strings.Localizable.Transfers.Cancellable.cancellingTransfers
            self.cancelTransferAlertController.message = nil
            self.cancelTransferAlertController.actions.first?.isEnabled = false
        }
    }
}
