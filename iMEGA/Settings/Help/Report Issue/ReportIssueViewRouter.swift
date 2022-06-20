
import SwiftUI

@available(iOS 14.0, *)
protocol ReportIssueViewRouting: Routing {
    func dismiss()
    func showAlert(title: String, message: String)
    func discardReportAlert()
    func cancelUploadReport(completion: @escaping (Bool) -> Void)
}

@available(iOS 14.0, *)
@objc class ReportIssueViewRouter: NSObject, ReportIssueViewRouting {
    
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    
    @objc init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    @objc func build() -> UIViewController {
        let areLogsEnabled = UserDefaults.standard.bool(forKey: "logging")
        
        let sdk = MEGASdkManager.sharedMEGASdk()
        let compressor = LogFileCompressor()
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYMMdd_hhmmss"
        let filename = "\(dateFormatter.string(from: date))_iOS_\(sdk.myEmail ?? "").zip"
        let zippedLogsUrl = areLogsEnabled ? compressor.compressedFileURL(sourceURL:Logger.shared().logsDirectoryUrl, toNewFilename: filename) : nil
        
        let uploadRepo = UploadFileRepository(sdk: sdk)
        let uploadUseCase = UploadFileUseCase(uploadFileRepository: uploadRepo, fileSystemRepository: FileSystemRepository.default, nodeRepository: NodeRepository.default, fileCacheRepository: FileCacheRepository.default)
        let supportRepo = SupportRepository(sdk: sdk)
        let supportUseCase = SupportUseCase(repo: supportRepo)
        let monitorRepo = NetworkMonitorRepository()
        let monitorUseCase = NetworkMonitorUseCase(repo: monitorRepo)
        let viewModel = ReportIssueViewModel(router: self,
                                             uploadFileUseCase: uploadUseCase,
                                             supportUseCase: supportUseCase,
                                             monitorUseCase: monitorUseCase,
                                             areLogsEnabled: areLogsEnabled,
                                             sourceUrl: zippedLogsUrl)
        let reportIssueView = ReportIssueView(viewModel: viewModel)
        
        let hostingController = UIHostingController(rootView: reportIssueView)
        hostingController.modalPresentationStyle = .fullScreen
        baseViewController = hostingController
        
        return hostingController
    }
    
    @objc func start() {
        presenter?.present(build(), animated: true)
    }
    
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default, handler: { [weak self] _ in
            self?.dismiss()
        }))
        baseViewController?.present(alertController, animated: true, completion: nil)
    }
    
    func discardReportAlert() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler:nil))
        alertController.addAction(UIAlertAction(title: Strings.Localizable.Help.ReportIssue.discardReport, style: .destructive, handler: { [weak self] _ in
            self?.dismiss()
        }))
        baseViewController?.present(alertController, animated: true, completion: nil)
    }
    
    func cancelUploadReport(completion: @escaping (Bool) -> Void) {
        let title = Strings.Localizable.Help.ReportIssue.Creating.Cancel.title
        let message = Strings.Localizable.Help.ReportIssue.Creating.Cancel.message
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.continue, style: .cancel, handler:nil))
        alertController.addAction(UIAlertAction(title: Strings.Localizable.yes, style: .destructive, handler: { _ in
            completion(true)
        }))
        baseViewController?.present(alertController, animated: true, completion: nil)
    }
}
