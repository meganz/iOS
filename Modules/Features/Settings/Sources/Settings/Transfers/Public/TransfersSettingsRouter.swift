import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import SwiftUI
import UIKit

public struct TransfersSettingsRouter: Routing {
    private weak var navigationController: UINavigationController?
    private let transferIndicatorConfigurator: ((UIViewController) -> Void)?

    public init(
        navigationController: UINavigationController?,
        transferIndicatorConfigurator: ((UIViewController) -> Void)? = nil
    ) {
        self.navigationController = navigationController
        self.transferIndicatorConfigurator = transferIndicatorConfigurator
    }

    public func build() -> UIViewController {
        let useCase = TransfersSettingsUseCase(repository: TransfersSettingsRepository.newRepo)
        let viewModel = TransfersSettingsViewModel(useCase: useCase)
        let transfersSettingsView = TransfersSettingsView(viewModel: viewModel)

        return UIHostingController(rootView: transfersSettingsView)
    }

    public func start() {
        let viewController = build()
        transferIndicatorConfigurator?(viewController)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
