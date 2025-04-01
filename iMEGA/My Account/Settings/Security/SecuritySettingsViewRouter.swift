import Foundation
import MEGAAppPresentation
import MEGAL10n

struct SecuritySettingsViewRouter: Routing {
    private weak var presenter: UINavigationController?
    
    init(presenter: UINavigationController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "SecurityOptionsTableViewControllerID")
    }
    
    func start() {
        let viewController = build()
        viewController.title = Strings.Localizable.Settings.Section.security
        presenter?.pushViewController(viewController, animated: true)
    }
}
