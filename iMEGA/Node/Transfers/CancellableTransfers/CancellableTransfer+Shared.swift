import MEGAAppPresentation
import UIKit

protocol CancellableTransferRouting: Routing {
    func showTransfersAlert()
    
    /// Called once a batch has been accepted without error, meaning every transfer was queued or
    /// needed no work at all. It does not mean the transfers have finished.
    ///
    /// - Parameters:
    ///   - message: User facing summary of what was accepted, e.g. "Download started".
    ///   - dismiss: Whether the cancel-transfer alert is on screen and should now be closed.
    func transferSuccess(with message: String, dismiss: Bool)
    func transferCancelled(with message: String, dismiss: Bool)
    func transferFailed(error: String, dismiss: Bool)
    func transferCompletedWithError(error: String, dismiss: Bool)
}

protocol CancellableTransferFlowLifecycleRouting: Routing {
    func transferFlowDidFinish()
}

enum CancellableTransferViewAction: ActionType {
    case onViewReady
    case didTapCancelButton
}

enum Command: Equatable, CommandType {
    case scanning(name: String, folders: UInt, files: UInt)
    case creatingFolders(createdFolders: UInt, totalFolders: UInt)
    case transferring
    case cancelling
}

/// Alias for `Command`, so the constraints below can name it without shadowing
/// `ViewModelType.Command`.
typealias CancellableTransferViewCommand = Command

/// Shape shared by every view model driving `CancellableTransferControllerWrapper`.
///
/// Pinning `Action` and `Command` lets the wrapper dispatch and receive them directly,
/// instead of casting through `ViewModelType`'s associated types.
protocol CancellableTransferViewModelProtocol: ViewModelType
where Action == CancellableTransferViewAction, Command == CancellableTransferViewCommand {}

/// View-model-agnostic face of `CancellableTransferControllerWrapper`, so a router can hold
/// a wrapper without naming the concrete view model type it was built with.
@MainActor
protocol CancellableTransferControllerWrapping {
    func createViewController() -> UIViewController
    func viewIsReady()
    func cancelAlertController() -> UIAlertController
}
