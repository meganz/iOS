import ChatRepo
import MEGADomain
import MEGAPresentation
import SwiftUI
import UIKit

public final class SetStatusViewRouter: Routing {
    private weak var navigationController: UINavigationController?
    private weak var baseViewController: UIViewController?
    
    public init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    public func build() -> UIViewController {
        let viewModel = SetStatusViewModel(
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            chatPresenceUseCase: ChatPresenceUseCase(repository: ChatPresenceRepository.newRepo)
        )
        let hostingVC = UIHostingController(
            rootView: SetStatusView(viewModel: viewModel)
        )
        baseViewController = hostingVC
        return hostingVC
    }
    
    public func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
}
