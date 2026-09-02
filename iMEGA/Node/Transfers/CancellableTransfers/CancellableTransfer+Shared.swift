import MEGAAppPresentation
import MEGAL10n

/// The outcome of a download transfer so listeners can react to it.
/// Currently we only handle `.transferQueued` and `.saved`.
@objc enum CancellableDownloadOutcome: Int {
    case transferQueued
    /// The node was saved without an actual SDK transfer (copied from the temp cache, or already in Offline).
    case saved

    var message: String {
        switch self {
        case .transferQueued: Strings.Localizable.downloadStarted
        case .saved: Strings.Localizable.saved
        }
    }
}

protocol CancellableTransferRouting: Routing {
    func showTransfersAlert()
    
    /// Called once a batch has been accepted without error, meaning every transfer was queued or
    /// needed no work at all. It does not mean the transfers have finished.
    ///
    /// - Parameters:
    ///   - message: User facing summary of what was accepted, e.g. "Download started".
    ///   - dismiss: Whether the cancel-transfer alert is on screen and should now be closed.
    ///   - downloadOutcome: How a download batch resolved, or nil for uploads. Implementations must
    ///     deliver it only after any dismissal has finished, because the alert stays the topmost
    ///     view controller until then and anything presented on it disappears with it.
    func transferSuccess(with message: String, dismiss: Bool, downloadOutcome: CancellableDownloadOutcome?)
    func transferCancelled(with message: String, dismiss: Bool)
    func transferFailed(error: String, dismiss: Bool)
    func transferCompletedWithError(error: String, dismiss: Bool)
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
