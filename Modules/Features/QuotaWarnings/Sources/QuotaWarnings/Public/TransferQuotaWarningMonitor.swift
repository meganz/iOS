import MEGAAppPresentation
import MEGADomain
import MEGAFoundation

public struct TransferQuotaWarningMonitor: Sendable {
    private let useCases: [any TransferAlmostFullDialogUseCaseProtocol]
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol

    /// - Parameter presentDialog: presents the dialog for the given severity, answering whether it was presented.
    /// The allowance is only spent for when the answer is true
    public init(presentDialog: @escaping @MainActor @Sendable (TransferQuotaSeverity) -> Bool) {
        self.init(
            useCases: [
                TransferAlmostFullDialogUseCase.limitedDownload(presentDialog: presentDialog),
                TransferAlmostFullDialogUseCase.limitedStreaming(presentDialog: presentDialog)
            ],
            remoteFeatureFlagUseCase: DIContainer.remoteFeatureFlagUseCase
        )
    }

    init(
        useCases: [any TransferAlmostFullDialogUseCaseProtocol],
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol
    ) {
        self.useCases = useCases
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
    }

    public func startMonitoring() async {
        guard await remoteFeatureFlagUseCase.isFeatureFlagEnabledAfterReady(for: .iosQuotaWarningsRevamp) else {
            MEGALog.log(level: .info, message: "[TransferQuotaWarningMonitor] skipped monitoring as the quota warnings revamp is off")
            return
        }

        await withTaskGroup(of: Void.self) { group in
            for useCase in useCases {
                guard !Task.isCancelled else { return }
                group.addTask { await useCase.monitorTransferQuotaState() }
            }
        }
    }
}
