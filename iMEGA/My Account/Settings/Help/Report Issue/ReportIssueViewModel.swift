import Combine
import MEGADomain

@available(iOS 14.0, *)
final class ReportIssueViewModel: ObservableObject {
    private let router: ReportIssueViewRouting
    private let uploadFileUseCase: UploadFileUseCaseProtocol
    private let supportUseCase: SupportUseCaseProtocol
    private var transfer: TransferEntity?
    private var sourceUrl: URL?
    private var detailsPlaceholder = Strings.Localizable.Help.ReportIssue.DescribeIssue.placeholder
    private var subscriptions: AnyCancellable?
    private let monitorUseCase: NetworkMonitorUseCaseProtocol
    var areLogsEnabled: Bool
    var shouldDisableSendButton: Bool {
        details.isEmpty || details == detailsPlaceholder || !isConnected
    }
    
    var isShowingPlaceholder: Bool {
        details == detailsPlaceholder
    }
    
    var shouldShowUploadLogFileView: Bool {
        isUploadingLog && areLogsEnabled && isSendLogFileToggleOn
    }
    
    @Published var progress: Float = 0
    @Published var isUploadingLog = false
    @Published var details = Strings.Localizable.Help.ReportIssue.DescribeIssue.placeholder
    @Published var isConnected = true
    var isSendLogFileToggleOn = true
    
    init(router: ReportIssueViewRouting,
         uploadFileUseCase: UploadFileUseCaseProtocol,
         supportUseCase: SupportUseCaseProtocol,
         monitorUseCase: NetworkMonitorUseCaseProtocol,
         areLogsEnabled: Bool = false,
         sourceUrl: URL?) {
        self.router = router
        self.uploadFileUseCase = uploadFileUseCase
        self.sourceUrl = sourceUrl
        self.areLogsEnabled = areLogsEnabled
        self.supportUseCase = supportUseCase
        self.monitorUseCase = monitorUseCase
        self.monitorUseCase.networkPathChanged(completion: { [weak self] (isConnected) in
            self?.isConnected = isConnected
        })
    }
    
    private func uploadLogFileIfNeeded() {
        guard let url = sourceUrl else {
            createTicketForSupport()
            return
        }
        uploadFileUseCase.uploadSupportFile(url) { [weak self] (transferEntity) in
            DispatchQueue.main.async {
                self?.transfer = transferEntity
                self?.isUploadingLog = true
            }
        } progress: { [weak self] (transferEntity) in
            DispatchQueue.main.async {
                self?.progress = Float(transferEntity.transferredBytes) / Float(transferEntity.totalBytes)
            }
        } completion: { [weak self] (result) in
            DispatchQueue.main.async {
                self?.isUploadingLog = false
                switch result {
                case .failure:
                    self?.router.showAlert(title: Strings.Localizable.somethingWentWrong,
                                           message: Strings.Localizable.Help.ReportIssue.Fail.message)
                case .success(let transferEntity):
                    self?.progress = 100
                    self?.createTicketForSupport(filename: transferEntity.fileName)
                }
            }
        }
    }
    
    private func createTicketForSupport(filename: String? = nil) {
        let message = """
        \(details)
        
        Report filename: \(filename ?? "No log file")
        """
        subscriptions = supportUseCase.createSupportTicket(withMessage: message)
            .sink(receiveCompletion: { [weak self] (completion) in
                switch completion {
                case .failure:
                    self?.router.showAlert(title: Strings.Localizable.somethingWentWrong,
                                           message: Strings.Localizable.Help.ReportIssue.Fail.message)
                case .finished:
                    self?.router.showAlert(title: Strings.Localizable.Help.ReportIssue.Success.title,
                                           message: Strings.Localizable.Help.ReportIssue.Success.message)
                }
            }, receiveValue: { _ in })
    }
    
    func createTicket() {
        if isSendLogFileToggleOn && areLogsEnabled {
            uploadLogFileIfNeeded()
        } else {
            createTicketForSupport()
        }
    }
    
    func cancelReport() {
        if details.isEmpty || details == detailsPlaceholder {
            router.dismiss()
        } else {
            router.discardReportAlert()
        }
    }
    
    func cancelUploadReport() {
        router.cancelUploadReport { [weak self] (cancelUpload) in
            if cancelUpload {
                guard let t = self?.transfer else {
                    self?.router.dismiss()
                    return
                }
                self?.uploadFileUseCase.cancel(transfer: t) { (result) in
                    switch result {
                    case .success():
                        MEGALogDebug("[Report issue] report canceled")
                    case .failure(_):
                        MEGALogError("[Report issue] fail cancel the report")
                        self?.router.dismiss()
                    }
                }
            }
        }
    }
}
