
protocol CancellableTransferRouting: Routing {
    func transferSuccess(with message: String)
    func transferCancelled(with message: String)
    func transferFailed(error: String)
    func transferCompletedWithError(error: String)
    func showConfirmCancel()
    func dismissConfirmCancel()
}

enum CancellableTransferViewAction: ActionType {
    case onViewReady
    case didTapCancelButton
    case didTapDismissConfirmCancel
    case didTapProceedCancel
}

enum Command: Equatable, CommandType {
    case confirmCancel
}
