import ChatRepo
import Foundation
import LogRepo
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGARepo
import MEGASDKRepo
import SwiftUI

public final class AboutViewRouter: Routing {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UINavigationController?
    private let appBundle: Bundle
    private let systemVersion: String
    private let deviceName: String
    
    public init(
        presenter: UINavigationController?,
        appBundle: Bundle,
        systemVersion: String,
        deviceName: String
    ) {
        self.presenter = presenter
        self.appBundle = appBundle
        self.systemVersion = systemVersion
        self.deviceName = deviceName
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
            deviceName: deviceName
        )
        let aboutView = AboutView(viewModel: aboutViewModel)
        let hostingController = UIHostingController(rootView: aboutView)
        baseViewController = hostingController
        baseViewController?.title = Strings.Localizable.about

        return hostingController
    }
    
    public func start() {
        presenter?.pushViewController(build(), animated: true)
    }
}
