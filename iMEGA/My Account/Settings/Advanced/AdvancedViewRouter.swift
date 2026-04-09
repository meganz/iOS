import Foundation
import MEGAAppPresentation

struct AdvancedViewRouter: Routing {
    
    private weak var presenter: UINavigationController?
    
    init(presenter: UINavigationController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "AdvancedTableViewControllerID")
    }
    
    func start() {
        let viewController = build()
        TransferIndicatorBarItemConfigurator.injectIfNeeded(into: viewController)
        presenter?.pushViewController(viewController, animated: true)
    }
}
