import ChatRepo
import MEGAAppPresentation
import MEGADomain
import MEGAPreference
import MEGARepo
import SwiftUI
import UIKit

public final class ChatMediaQualityViewRouter: Routing {
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
        let viewModel = ChatMediaQualityViewModel(
            defaultPreferenceUseCase: PreferenceUseCase.default,
            groupPreferenceUseCase: PreferenceUseCase(
                repository: PreferenceRepository(userDefaults: UserDefaults(suiteName: "group.mega.ios")!)
            )
        )
        let hostingVC = UIHostingController(
            rootView: ChatMediaQualityView(viewModel: viewModel)
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
