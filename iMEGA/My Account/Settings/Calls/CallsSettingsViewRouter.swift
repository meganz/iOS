import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

final class CallsSettingsViewRouter: Routing {
    private weak var presenter: UINavigationController?
    
    init(presenter: UINavigationController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let analyticsEventUseCase = AnalyticsEventUseCase(repository: AnalyticsRepository(sdk: MEGASdk.shared))
        let viewModel = CallsSettingsViewModel(analyticsEventUseCase: analyticsEventUseCase)
        
        return if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newSetting) {
            UIHostingController(rootView: CallsSettingsView(viewModel: viewModel))
        } else {
            UIHostingController(rootView: LegacyCallsSettingsView(viewModel: viewModel))
        }
    }
    
    func start() {
        let viewController = build()
        viewController.title = Strings.Localizable.Settings.Section.Calls.title
        presenter?.pushViewController(viewController, animated: true)
    }
}
