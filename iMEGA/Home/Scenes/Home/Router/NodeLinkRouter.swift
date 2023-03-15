import Foundation

final class NodeLinkRouter: NSObject {

    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
    }

    // MARK: - Public

    func showLinkManagement(for node: MEGANode) {
        CopyrightWarningViewController.presentGetLinkViewController(for: [node], in: navigationController)
    }
}
