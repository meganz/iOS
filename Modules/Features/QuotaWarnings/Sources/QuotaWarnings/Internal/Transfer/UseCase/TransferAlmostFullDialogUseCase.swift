import MEGAAppSDKRepo
import MEGADomain
import MEGAFoundation

struct TransferAlmostFullDialogUseCase: TransferAlmostFullDialogUseCaseProtocol {
    enum TransferQuotaActivity {
        case download, streaming
    }
    
    private let stateProvider: any TransferQuotaStateProviding
    private let allowance: any DialogDisplayAllowance
    private let activity: TransferQuotaActivity
    private let presentDialog: @MainActor @Sendable (TransferQuotaSeverity) -> Bool

    private var severity: TransferQuotaSeverity {
        switch activity {
        case .download:
                .limitedDownload
        case .streaming:
                .limitedStreaming
        }
    }
    
    init(
        stateProvider: some TransferQuotaStateProviding,
        allowance: some DialogDisplayAllowance,
        activity: TransferQuotaActivity,
        presentDialog: @escaping @MainActor @Sendable (TransferQuotaSeverity) -> Bool
    ) {
        self.stateProvider = stateProvider
        self.allowance = allowance
        self.activity = activity
        self.presentDialog = presentDialog
    }

    func monitorTransferQuotaState() async {
        MEGALog.log(level: .info, message: "\(logTag) started monitoring transfer quota states")
        for await case .orange in stateProvider.states {
            guard !Task.isCancelled else {
                MEGALog.log(level: .info, message: "\(logTag) stopped monitoring: the owning task was cancelled")
                return
            }
            
            await presentDialogIfAllowed()
        }
        MEGALog.log(level: .info, message: "\(logTag) stopped monitoring: the state sequence finished")
    }

    private func presentDialogIfAllowed() async {
        guard allowance.isAvailable else {
            MEGALog.log(level: .info, message: "\(logTag) skipped present as allowance is already spent")
            return
        }
        
        guard await presentDialog(severity) else {
            MEGALog.log(level: .warning, message: "\(logTag) skipped present as the presenter refused")
            return
        }
        allowance.consume()
        MEGALog.log(level: .info, message: "\(logTag) presented the dialog and spent allowance")
    }

    private var logTag: String {
        switch activity {
        case .download: "[TransferAlmostFullDialog][limited download]"
        case .streaming: "[TransferAlmostFullDialog][limited streaming]"
        }
    }
}

// MARK: - Triggers
extension TransferAlmostFullDialogUseCase {
    static func limitedDownload(
        presentDialog: @escaping @MainActor @Sendable (TransferQuotaSeverity) -> Bool
    ) -> TransferAlmostFullDialogUseCase {
        TransferAlmostFullDialogUseCase(
            stateProvider: DownloadTransferQuotaStateProvider.shared,
            allowance: DailyDialogAllowance.transferAlmostFullLimitedDownload,
            activity: .download,
            presentDialog: presentDialog
        )
    }

    static func limitedStreaming(
        presentDialog: @escaping @MainActor @Sendable (TransferQuotaSeverity) -> Bool
    ) -> TransferAlmostFullDialogUseCase {
        TransferAlmostFullDialogUseCase(
            stateProvider: StreamingTransferQuotaStateProvider.shared,
            allowance: DailyDialogAllowance.transferAlmostFullLimitedStreaming,
            activity: .streaming,
            presentDialog: presentDialog
        )
    }
}
