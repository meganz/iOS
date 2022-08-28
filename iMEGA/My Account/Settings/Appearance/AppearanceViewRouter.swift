import Foundation

struct AppearanceViewRouter: Routing {
    
    private weak var presenter: UINavigationController?
    
    init(presenter: UINavigationController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let storyboard = UIStoryboard(name: "Appearance", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "AppearanceTableViewControllerID")
    }
    
    func start() {
        let viewController = build()
        presenter?.pushViewController(viewController, animated: true)
    }
}
