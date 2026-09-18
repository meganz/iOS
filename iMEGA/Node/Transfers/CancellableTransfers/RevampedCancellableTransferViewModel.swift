import MEGAAppPresentation
import MEGADomain
import MEGAFoundation
import MEGAL10n

@MainActor
final class RevampedCancellableTransferViewModel: CancellableTransferViewModelProtocol {
    typealias RoutingProtocols = CancellableTransferRouting & CancellableTransferFlowLifecycleRouting & TransferWidgetRouting

    private enum CancellableTransferOutcome: Sendable {
        case cancelledByUser
        case startedTransferring
        case failed
    }
    
    private let router: any RoutingProtocols
    private let cancellableTransferUseCase: any CancellableTransferUseCaseProtocol
    private let overDiskQuotaChecker: any OverDiskQuotaChecking
    private let alertScheduler: any CancellableTransferAlertScheduling
    private let transfers: [CancellableTransfer]
    private let transferType: CancellableTransferType
    
    private var transferTask: Task<Void, Never>?
    
    private var transferOutcome: CancellableTransferOutcome?

    var invokeCommand: ((Command) -> Void)?

    init(
        router: some RoutingProtocols,
        cancellableTransferUseCase: some CancellableTransferUseCaseProtocol,
        overDiskQuotaChecker: some OverDiskQuotaChecking,
        alertScheduler: some CancellableTransferAlertScheduling,
        transfers: [CancellableTransfer],
        transferType: CancellableTransferType
    ) {
        self.router = router
        self.cancellableTransferUseCase = cancellableTransferUseCase
        self.overDiskQuotaChecker = overDiskQuotaChecker
        self.alertScheduler = alertScheduler
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
                MEGALog.log(level: .info, message: "[CancellableTransfer] batch not started: over disk quota, or nothing to transfer")
                router.transferFlowDidFinish()
                return
            }
            router.prepareTransfersWidget()
            startTransfers()
            alertScheduler.scheduleForPresent()
        case .didTapCancelButton:
            cancelTransfers()
        }
    }

    // MARK: - Transfers

    private func startTransfers() {
        transferTask?.cancel()
        transferOutcome = nil
        let batch = transfers.map(\.cancellableTransferEntity)
        MEGALog.log(level: .info, message: "[CancellableTransfer] starting \(transferType) batch of \(batch.count) transfer(s)")
        transferTask = Task { [weak self, cancellableTransferUseCase] in
            for await state in cancellableTransferUseCase.start(transfers: batch) {
                guard !Task.isCancelled else {
                    MEGALog.log(level: .debug, message: "[CancellableTransfer] abandoning states: view model task cancelled")
                    break
                }
                
                if self?.handle(state) == true {
                    MEGALog.log(level: .debug, message: "[CancellableTransfer] abandoning states: terminal state reached")
                    break
                }
            }
            
            MEGALog.log(level: .debug, message: "[CancellableTransfer] stopped reading states")
            
            await self?.finish()
        }
    }

    private func cancelTransfers() {
        MEGALog.log(level: .info, message: "[CancellableTransfer] cancel requested by the user")
        invokeCommand?(.cancelling)
        transferOutcome = .cancelledByUser
        transferTask?.cancel()
        cancellableTransferUseCase.cancel()
    }

    // MARK: - Transfer state
    
    /// Displays each state emitted by the use case, and records the transferOutcome of a terminal state
    /// Returns: A boolean indicate if the state is terminal state such the flow should be ended.
    private func handle(_ state: CancellableTransferStateEntity) -> Bool {
        MEGALog.log(level: .debug, message: "[CancellableTransfer] state: \(state)")
        
        let shouldFinish: Bool
        
        switch state {
        case .scanning(let name, let folderCount, let fileCount):
            invokeCommand?(.scanning(name: name, folders: folderCount, files: fileCount))
            shouldFinish = false
        case .creatingFolders(let created, let total):
            invokeCommand?(.creatingFolders(createdFolders: created, totalFolders: total))
            shouldFinish = false
        case .transferringFiles:
            transferOutcome = .startedTransferring
            shouldFinish = true
        case .failed:
            transferOutcome = .failed
            shouldFinish = true
        }
        
        return shouldFinish
    }

    /// Dismisses the cancel-transfers alert if needed, routes the flow result's message and tears the flow down.
    private func finish() async {
        guard transferOutcome != nil else { return }

        let presented = await alertScheduler.finish()

        guard let transferOutcome else { return }

        switch transferOutcome {
        case .cancelledByUser:
            router.transferCancelled(with: Strings.Localizable.transferCancelled, dismiss: presented)
        case .startedTransferring:
            router.transferSuccess(with: transfersStartedMessage, dismiss: presented)
        case .failed:
            router.transferFailed(
                error: String(format: "%@ %@", Strings.Localizable.transferFailed, Strings.Localizable.somethingWentWrong),
                dismiss: presented
            )
        }
        router.transferFlowDidFinish()
    }

    private var transfersStartedMessage: String {
        switch transferType {
        case .upload: Strings.Localizable.uploadStartedMessage
        case .download, .downloadChat, .downloadFileLink: Strings.Localizable.downloadStarted
        }
    }
}
