import MEGAAppPresentation
import MEGADomain
import MEGAFoundation
import MEGAL10n

@MainActor
final class RevampedCancellableTransferViewModel: CancellableTransferViewModelProtocol {
    typealias RoutingProtocols = CancellableTransferRouting & CancellableTransferFlowLifecycleRouting & TransferWidgetRouting

    private let router: any RoutingProtocols
    private let cancellableTransferUseCase: any CancellableTransferUseCaseProtocol
    private let overDiskQuotaChecker: any OverDiskQuotaChecking
    private let transfers: [CancellableTransfer]
    private let transferType: CancellableTransferType

    private var transferTask: Task<Void, Never>?

    var invokeCommand: ((Command) -> Void)?

    init(
        router: some RoutingProtocols,
        cancellableTransferUseCase: some CancellableTransferUseCaseProtocol,
        overDiskQuotaChecker: some OverDiskQuotaChecking,
        transfers: [CancellableTransfer],
        transferType: CancellableTransferType
    ) {
        self.router = router
        self.cancellableTransferUseCase = cancellableTransferUseCase
        self.overDiskQuotaChecker = overDiskQuotaChecker
        self.transfers = transfers
        self.transferType = transferType
    }

    deinit {
        transferTask?.cancel()
    }

    // MARK: - Dispatch action

    func dispatch(_ action: CancellableTransferViewAction) {
        switch action {
        case .onViewReady:
            guard !overDiskQuotaChecker.showOverDiskQuotaIfNeeded(), transfers.isNotEmpty else {
                MEGALog.log(level: .info, message: "[CancellableTransfer] batch not started: over disk quota")
                router.transferFlowDidFinish()
                return
            }
            router.prepareTransfersWidget()
            startTransfers()
            // Alert scheduling will be handlled in next MR
            router.showTransfersAlert()
        case .didTapCancelButton:
            cancelTransfers()
        }
    }

    // MARK: - Transfers

    private func startTransfers() {
        transferTask?.cancel()
        let batch = transfers.map(\.cancellableTransferEntity)
        MEGALog.log(level: .info, message: "[CancellableTransfer] starting \(transferType) batch of \(batch.count) transfer(s)")
        transferTask = Task { [weak self, cancellableTransferUseCase] in
            for await state in cancellableTransferUseCase.start(transfers: batch) {
                guard !Task.isCancelled else {
                    MEGALog.log(level: .debug, message: "[CancellableTransfer] abandoning states: view model task cancelled")
                    break
                }
                self?.handle(state)
            }
            MEGALog.log(level: .debug, message: "[CancellableTransfer] stopped reading states")
            if Task.isCancelled {
                self?.handleCancelled()
            }
        }
    }

    private func cancelTransfers() {
        MEGALog.log(level: .info, message: "[CancellableTransfer] cancel requested by the user")
        invokeCommand?(.cancelling)
        transferTask?.cancel()
        cancellableTransferUseCase.cancel()
    }

    private func handleCancelled() {
        finish { router.transferCancelled(with: Strings.Localizable.transferCancelled, dismiss: true) }
    }
    
    // MARK: - Transfer state
    
    /// Routes each state emitted by the use case.
    private func handle(_ state: CancellableTransferStateEntity) {
        MEGALog.log(level: .debug, message: "[CancellableTransfer] state: \(state)")
        
        switch state {
        case .scanning(let name, let folderCount, let fileCount):
            invokeCommand?(.scanning(name: name, folders: folderCount, files: fileCount))
        case .creatingFolders(let created, let total):
            invokeCommand?(.creatingFolders(createdFolders: created, totalFolders: total))
        case .transferringFiles:
            // Download outcome will be handled in next MR
            finish { router.transferSuccess(with: transfersStartedMessage, dismiss: true, downloadOutcome: nil) }
        case .failed:
            MEGALog.log(level: .error, message: "[CancellableTransfer] batch failed: no transfer of it got away")
            finish {
                router.transferFailed(
                    error: String(format: "%@ %@", Strings.Localizable.transferFailed, Strings.Localizable.somethingWentWrong),
                    dismiss: true)
            }
        }
    }

    /// Routes the flow's last word and tears the flow down.
    ///
    /// Only the first terminal state gets through: a cancelled batch keeps reporting states, and
    /// none of the ones that follow has anything left to say.
    private func finish(_ route: () -> Void) {
        route()
        router.transferFlowDidFinish()
    }

    private var transfersStartedMessage: String {
        switch transferType {
        case .upload: Strings.Localizable.uploadStartedMessage
        case .download, .downloadChat, .downloadFileLink: Strings.Localizable.downloadStarted
        }
    }
}
