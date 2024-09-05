import ChatRepo
import LogRepo
import MEGADomain
import MEGAPresentation
import MEGARepo
import MEGASDKRepo
import SwiftUI

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
        
        let sdk = MEGASdk.shared
        let compressor = LogFileCompressor()
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYMMdd_hhmmss"
        let filename = "\(dateFormatter.string(from: date))_iOS_\(sdk.myEmail ?? "").zip"
        let zippedLogsUrl = areLogsEnabled ? compressor.compressedFileURL(sourceURL: Logger.shared().logsDirectoryUrl, toNewFilename: filename) : nil
        
        let uploadRepo = UploadFileRepository(sdk: sdk)
        let uploadUseCase = UploadFileUseCase(uploadFileRepository: uploadRepo, fileSystemRepository: FileSystemRepository.newRepo, nodeRepository: NodeRepository.newRepo, fileCacheRepository: FileCacheRepository.newRepo)
        let monitorRepo = NetworkMonitorRepository.newRepo
        let monitorUseCase = NetworkMonitorUseCase(repo: monitorRepo)
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        let supportUseCase = makeSupportUseCase(sdk: sdk, accountUseCase: accountUseCase)
        let viewModel = ReportIssueViewModel(router: self,
                                             uploadFileUseCase: uploadUseCase,
                                             supportUseCase: supportUseCase,
                                             monitorUseCase: monitorUseCase,
                                             accountUseCase: accountUseCase,
                                             areLogsEnabled: areLogsEnabled,
                                             sourceUrl: zippedLogsUrl)
        let reportIssueView = ReportIssueView(viewModel: viewModel)
        
        let hostingController = UIHostingController(rootView: reportIssueView)
        baseViewController = hostingController
        return hostingController
    }
    
    private func makeSupportUseCase(sdk: MEGASdk, accountUseCase: any AccountUseCaseProtocol) -> any SupportUseCaseProtocol {
        let supportRepo = SupportRepository.newRepo
        let supportUseCase = SupportUseCase(repo: supportRepo)
        return supportUseCase
    }
    
    @objc func start() {
        presenter?.present(build(), animated: true)
    }
    
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
}
