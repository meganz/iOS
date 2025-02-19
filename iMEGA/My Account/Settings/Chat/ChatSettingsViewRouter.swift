import Foundation
import MEGAPresentation

struct ChatSettingsViewRouter: Routing {
    private weak var presenter: UINavigationController?
    
    init(presenter: UINavigationController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let storyboard = UIStoryboard(name: "ChatSettings", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "ChatSettingsTableViewControllerID")
    }
    
    func start() {
        let viewController = build()
        presenter?.pushViewController(viewController, animated: true)
    }
}
