import ChatRepo
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import Settings
import SwiftUI

final class ChatSettingsViewRouter: Routing {
    private weak var presenter: UINavigationController?
    private weak var baseViewController: UIViewController?

    init(presenter: UINavigationController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newSetting) {
            let viewModel = ChatSettingsViewModel(
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
                chatPresenceUseCase: ChatPresenceUseCase(repository: ChatPresenceRepository.newRepo),
                navigateToStatus: navigateToStatus,
                navigateToNotifications: navigateToNotifications,
                navigateToMediaQuality: navigateToMediaQuality
            )
            
            let hostingVC = UIHostingController(rootView: ChatSettingsView(viewModel: viewModel))
            hostingVC.navigationItem.backButtonTitle = ""
            baseViewController = hostingVC
            return hostingVC
        } else {
            let storyboard = UIStoryboard(name: "ChatSettings", bundle: nil)
            return storyboard.instantiateViewController(withIdentifier: "ChatSettingsTableViewControllerID")
        }
    }
    
    func start() {
        let viewController = build()
        presenter?.pushViewController(viewController, animated: true)
    }
    
    func navigateToStatus() {
        guard let presenter else { return }
        SetStatusViewRouter(navigationController: presenter).start()
    }
    
    func navigateToNotifications() {
        guard let presenter else { return }
        NotificationSettingsViewRouter(
            navigationController: presenter
        ).start()
    }
    
    func navigateToMediaQuality() {
        guard let presenter else { return }
        ChatMediaQualityViewRouter(navigationController: presenter).start()
    }
}
