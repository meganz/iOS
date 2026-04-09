import ChatRepo
import MEGAAppPresentation
import MEGADomain
import SwiftUI
import UIKit

public final class NotificationSettingsViewRouter: Routing {
    private weak var navigationController: UINavigationController?
    private weak var baseViewController: UIViewController?
    private let transferIndicatorConfigurator: ((UIViewController) -> Void)?

    public init(
        navigationController: UINavigationController?,
        transferIndicatorConfigurator: ((UIViewController) -> Void)? = nil
    ) {
        self.navigationController = navigationController
        self.transferIndicatorConfigurator = transferIndicatorConfigurator
    }
    
    public func build() -> UIViewController {
        let viewModel = NotificationSettingsViewModel(
            notificationSettingsUseCase: NotificationSettingsUseCase(repository: NotificationSettingsRepository.newRepo)
        )
        let hostingVC = UIHostingController(
            rootView: NotificationSettingsView(viewModel: viewModel)
        )
        baseViewController = hostingVC
        return hostingVC
    }
    
    public func start() {
        let viewController = build()
        transferIndicatorConfigurator?(viewController)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
