import MEGADomain
import MEGAFoundation

public struct TransferQuotaWarningMonitor: Sendable {
    private let useCases: [any TransferAlmostFullDialogUseCaseProtocol]

    /// - Parameter presentDialog: presents the dialog for the given severity, answering whether it was presented.
    /// The allowance is only spent for when the answer is true
    public init(presentDialog: @escaping @MainActor @Sendable (TransferQuotaSeverity) -> Bool) {
        self.init(
            useCases: [
                TransferAlmostFullDialogUseCase.limitedDownload(presentDialog: presentDialog),
                TransferAlmostFullDialogUseCase.limitedStreaming(presentDialog: presentDialog)
            ]
        )
    }

    init(useCases: [any TransferAlmostFullDialogUseCaseProtocol]) {
        self.useCases = useCases
    }

    public func startMonitoring() async {
        await withTaskGroup(of: Void.self) { group in
            for useCase in useCases {
                guard !Task.isCancelled else { return }
                group.addTask { await useCase.monitorTransferQuotaState() }
            }
        }
    }
}
