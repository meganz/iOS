import MEGAPresentation
import SwiftUI

protocol QASettingsRouting: Routing {
    func showAlert(withTitle title: String, message: String, actions: [UIAlertAction])
    func showAlert(withError error: Error) 
}

struct QASettingsRouter: QASettingsRouting {
    private enum Constants {
        static let screenTitle = "QA Settings"
        static let errorAlertTitle = "Error"
    }
    
    private weak var presenter: UINavigationController?
    
    init(presenter: UINavigationController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let viewModel = QASettingsViewModel(router: self)
        let view = QASettingsView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)
        controller.title = Constants.screenTitle
        return controller
    }
    
    func start() {
        presenter?.pushViewController(build(), animated: true)
    }
    
    func showAlert(withTitle title: String, message: String, actions: [UIAlertAction]) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach(alertController.addAction)
        presenter?.present(alertController, animated: true, completion: nil)
    }
    
    func showAlert(withError error: Error) {
        showAlert(
            withTitle: Constants.errorAlertTitle,
            message: error.localizedDescription,
            actions: [UIAlertAction(title: Strings.Localizable.ok, style: .cancel, handler: nil)]
        )
    }
}
