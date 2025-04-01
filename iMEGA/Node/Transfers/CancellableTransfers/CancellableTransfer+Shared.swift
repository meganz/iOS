import MEGAAppPresentation

protocol CancellableTransferRouting: Routing {
    func showTransfersAlert()
    func transferSuccess(with message: String, dismiss: Bool)
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
