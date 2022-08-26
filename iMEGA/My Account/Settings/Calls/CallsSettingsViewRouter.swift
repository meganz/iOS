import SwiftUI

final class CallsSettingsViewRouter: Routing {
    private weak var presenter: UINavigationController?
    
    init(presenter: UINavigationController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let callsSettingsView = CallsSettingsView(viewModel: CallsSettingsViewModel())
        let hostingController = UIHostingController(rootView: callsSettingsView)
        return hostingController
    }
    
    func start() {
        let viewController = build()
        viewController.title = Strings.Localizable.Settings.Section.Calls.title
        presenter?.pushViewController(viewController, animated: true)
    }
}
