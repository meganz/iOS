import ChatRepo
import MEGAAppPresentation
import MEGADomain
import SwiftUI
import UIKit

public final class NotificationSettingsViewRouter: Routing {
    private weak var navigationController: UINavigationController?
    private weak var baseViewController: UIViewController?

    public init(
        navigationController: UINavigationController?
    ) {
        self.navigationController = navigationController
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
        navigationController?.pushViewController(build(), animated: true)
    }
}
