
protocol CancellableTransferRouting: Routing {
    func showTransfersAlert()
    func transferSuccess(with message: String)
    func transferCancelled(with message: String)
    func transferFailed(error: String)
    func transferCompletedWithError(error: String)
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
