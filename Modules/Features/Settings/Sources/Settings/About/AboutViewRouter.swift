import ChatRepo
import Foundation
import LogRepo
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGARepo
import SwiftUI

public final class AboutViewRouter: Routing {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UINavigationController?
    private let appBundle: Bundle
    private let systemVersion: String
    private let deviceName: String
    private let transferIndicatorConfigurator: ((UIViewController) -> Void)?
    private let diagnosticsFile: AboutDiagnosticsFile?

    public init(
        presenter: UINavigationController?,
        appBundle: Bundle,
        systemVersion: String,
        deviceName: String,
        transferIndicatorConfigurator: ((UIViewController) -> Void)? = nil,
        diagnosticsFile: AboutDiagnosticsFile? = nil
    ) {
        self.presenter = presenter
        self.appBundle = appBundle
        self.systemVersion = systemVersion
        self.deviceName = deviceName
        self.transferIndicatorConfigurator = transferIndicatorConfigurator
        self.diagnosticsFile = diagnosticsFile
    }
    
    public func build() -> UIViewController {
        let preferenceUseCase = PreferenceUseCase(repository: PreferenceRepository.newRepo)
        let aboutViewModel =  AboutViewModel(
            preferenceUC: preferenceUseCase,
            apiEnvironmentUC: APIEnvironmentUseCase(apiEnvironmentRepository: APIEnvironmentRepository.newRepo,
                                                    chatURLRepository: ChatURLRepository.newRepo),
            manageLogsUC: ManageLogsUseCase(repository: LogSettingRepository.newRepo,
                                            preferenceUseCase: preferenceUseCase),
            changeSfuServerUC: ChangeSfuServerUseCase(repository: ChangeSfuServerRepository.newRepo),
            appBundle: appBundle,
            systemVersion: systemVersion,
            deviceName: deviceName,
            diagnosticsFile: diagnosticsFile
        )
        aboutViewModel.shareDiagnosticsFile = { [weak self] fileURL in
            self?.presentShareSheet(for: fileURL)
        }
        let aboutView = AboutView(viewModel: aboutViewModel)
        let hostingController = UIHostingController(rootView: aboutView)
        baseViewController = hostingController
        baseViewController?.title = Strings.Localizable.about

        return hostingController
    }
    
    private func presentShareSheet(for fileURL: URL) {
        guard let baseViewController else { return }
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = baseViewController.view
        baseViewController.present(activityViewController, animated: true)
    }

    public func start() {
        let viewController = build()
        transferIndicatorConfigurator?(viewController)
        presenter?.pushViewController(viewController, animated: true)
    }
}
