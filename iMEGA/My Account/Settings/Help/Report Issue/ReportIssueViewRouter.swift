
import SwiftUI
import MEGADomain
import MEGAData
import MEGAPresentation

protocol ReportIssueViewRouting: Routing {
    func dismiss()
}

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
        let zippedLogsUrl = areLogsEnabled ? compressor.compressedFileURL(sourceURL: Logger.shared().logsDirectoryUrl, toNewFilename: filename) : nil
        
        let uploadRepo = UploadFileRepository(sdk: sdk)
        let uploadUseCase = UploadFileUseCase(uploadFileRepository: uploadRepo, fileSystemRepository: FileSystemRepository.newRepo, nodeRepository: NodeRepository.newRepo, fileCacheRepository: FileCacheRepository.newRepo)
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
}
