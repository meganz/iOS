import ChatRepo
import MEGAAppPresentation
import MEGADomain
import SwiftUI
import UIKit

public final class SetStatusViewRouter: Routing {
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
        let viewController = build()
        transferIndicatorConfigurator?(viewController)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
