import MEGADomain
import MEGAL10n

final class ReportIssueViewModel: ObservableObject {
    private let router: any ReportIssueViewRouting
    private let uploadFileUseCase: any UploadFileUseCaseProtocol
    private let supportUseCase: any SupportUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let monitorUseCase: any NetworkMonitorUseCaseProtocol
    private var transfer: TransferEntity?
    private var sourceUrl: URL?
    private var detailsPlaceholder = Strings.Localizable.Help.ReportIssue.DescribeIssue.placeholder
    private (set) var reportAlertType: ReportIssueAlertTypeModel = .none
    
    var areLogsEnabled: Bool
    var shouldDisableSendButton: Bool {
        details.isEmpty || details == detailsPlaceholder || !isConnected
    }
    
    var shouldShowUploadLogFileView: Bool {
        isUploadingLog && areLogsEnabled && isSendLogFileToggleOn
    }
    
    var isReportDiscardable: Bool {
        !(details.isEmpty || details == detailsPlaceholder)
    }
    
    @Published var progress: Float = 0
    @Published var isUploadingLog = false
    @Published var details = ""
    @Published var isConnected = true
    @Published var showingReportIssueActionSheet = false
    @Published var showingReportIssueAlert = false
    @Published var isNotReachingMinimumCharacter = false
    
    var isSendLogFileToggleOn = true
    
    init(router: some ReportIssueViewRouting,
         uploadFileUseCase: some UploadFileUseCaseProtocol,
         supportUseCase: some SupportUseCaseProtocol,
         monitorUseCase: some NetworkMonitorUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         areLogsEnabled: Bool = false,
         sourceUrl: URL?
    ) {
        self.router = router
        self.uploadFileUseCase = uploadFileUseCase
        self.sourceUrl = sourceUrl
        self.areLogsEnabled = areLogsEnabled
        self.supportUseCase = supportUseCase
        self.monitorUseCase = monitorUseCase
        self.accountUseCase = accountUseCase
    }
    
    private func uploadLogFileIfNeeded() async {
        guard let sourceUrl else {
            await createTicketForSupport()
            return
        }
        
        do {
            let transfer = try await uploadLogFile(from: sourceUrl)
            await handleUploadSuccess(transfer: transfer)
        } catch {
            await handleUploadFailure()
        }
    }
    
    private func uploadLogFile(from sourceUrl: URL) async throws -> TransferEntity {
        try await uploadFileUseCase.uploadSupportFile(sourceUrl) { [weak self] transfer in
            guard let self else { return }
            Task {
                await self.updateCurrentTransfer(transfer)
            }
        } progress: { [weak self] transfer in
            guard let self else { return }
            Task {
                await self.updateCurrentProgress(Float(transfer.transferredBytes) / Float(transfer.totalBytes))
            }
        }
    }

    @MainActor
    private func updateCurrentTransfer(_ transfer: TransferEntity) {
        self.transfer = transfer
        isUploadingLog = true
    }

    @MainActor
    private func updateCurrentProgress(_ progress: Float) {
        self.progress = progress
    }
    
    @MainActor
    private func handleUploadSuccess(transfer: TransferEntity) async {
        progress = 1
        isUploadingLog = false
        await createTicketForSupport(filename: transfer.fileName)
    }
    
    @MainActor
    private func handleUploadFailure() async {
        isUploadingLog = false
        reportAlertType = .uploadLogFileFailure
        showingReportIssueAlert = true
    }
    
    @MainActor
    private func createTicketForSupport(filename: String? = nil) async {
        do {
            let formattedMessage = await getFormattedReportIssueMessage(details, filename: filename)
            try await supportUseCase.createSupportTicket(withMessage: formattedMessage)
            reportAlertType = .createSupportTicketFinished
        } catch {
            if let err = error as? ReportErrorEntity, case .tooManyRequest = err {
                reportAlertType = .createSupportTicketTooManyRequestFailure
            } else {
                reportAlertType = .createSupportTicketFailure
            }
        }
        showingReportIssueAlert = true
    }
    
    @MainActor
    private func getFormattedReportIssueMessage(_ message: String, filename: String? = nil) async -> String {
        let appMetaDataFactory = AppMetaDataFactory(bundle: .main)
        let deviceMetaDataFactory = DeviceMetaDataFactory(bundle: .main, locale: NSLocale.current as NSLocale)
        let messageViewModel = ReportIssueMessageViewModel(accountUseCase: accountUseCase, appMetaData: appMetaDataFactory.make(), deviceMetaData: deviceMetaDataFactory.make())
        return await messageViewModel.generateReportIssueMessage(message: message, filename: filename ?? "No log file")
    }
    
    func createTicket() async {
        if isSendLogFileToggleOn && areLogsEnabled {
            await uploadLogFileIfNeeded()
        } else {
            await createTicketForSupport()
        }
    }
    
    func cancelUploadReport() async {
        guard let transfer else {
            await dismissReport()
            return
        }
        
        do {
            try await uploadFileUseCase.cancel(transfer: transfer)
            MEGALogDebug("[Report issue] report canceled")
        } catch {
            MEGALogError("[Report issue] fail cancel the report")
            await dismissReport()
        }
    }
    
    @MainActor
    func dismissReport() {
        router.dismiss()
    }
    
    @MainActor
    func showCancelUploadReportAlert() {
        reportAlertType = .cancelUploadReport
        showingReportIssueAlert = true
    }
    
    @MainActor
    func showReportIssueActionSheetIfNeeded() {
        showingReportIssueActionSheet = !(details.isEmpty || details == detailsPlaceholder)
        if !showingReportIssueActionSheet {
            dismissReport()
        }
    }
    
    func reportIssueAlertData() -> ReportIssueAlertDataModel {
        switch reportAlertType {
        case .createSupportTicketTooManyRequestFailure:
            ReportIssueAlertDataModel(
                title: Strings.Localizable.Help.ReportIssue.Fail.Too.Many.Request.title,
                message: Strings.Localizable.Help.ReportIssue.Fail.Too.Many.Request.message,
                primaryButtonTitle: Strings.Localizable.ok
            )
        case .uploadLogFileFailure, .createSupportTicketFailure:
            ReportIssueAlertDataModel(
                title: Strings.Localizable.somethingWentWrong,
                message: Strings.Localizable.Help.ReportIssue.Fail.message,
                primaryButtonTitle: Strings.Localizable.ok
            )
        case .createSupportTicketFinished:
            ReportIssueAlertDataModel(
                title: Strings.Localizable.Help.ReportIssue.Success.title,
                message: Strings.Localizable.Help.ReportIssue.Success.message,
                primaryButtonTitle: Strings.Localizable.ok,
                primaryButtonAction: dismissReport
            )
        case .cancelUploadReport:
            ReportIssueAlertDataModel(
                title: Strings.Localizable.Help.ReportIssue.Creating.Cancel.title,
                message: Strings.Localizable.Help.ReportIssue.Creating.Cancel.message,
                primaryButtonTitle: Strings.Localizable.continue,
                primaryButtonAction: dismissReport,
                secondaryButtonTitle: Strings.Localizable.yes,
                secondaryButtonAction: cancelUploadReport
            )
        case .none:
            ReportIssueAlertDataModel()
        }
    }
    
    @MainActor
    func monitorNetworkChanges() async {
        for await isConnected in monitorUseCase.connectionChangedStream {
            self.isConnected = isConnected
        }
    }
}
