import Foundation

final class NodeInfoRouter: NSObject {

    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
    }

    // MARK: - Info

    func showInformation(for node: MEGANode) {
        let nodeInfoNavigation = UIStoryboard(name: "Node", bundle: nil)
            .instantiateViewController(withIdentifier: "NodeInfoNavigationControllerID") as! UINavigationController
        guard let nodeInfoVC = nodeInfoNavigation.viewControllers.first as? NodeInfoViewController else { return }

        nodeInfoVC.display(node, withDelegate: self)
        navigationController?.present(nodeInfoNavigation, animated: true, completion: nil)
    }
    
    // MARK: - Version
    
    func showVersions(for node: MEGANode) {
        guard let nodeVersionNavigation = navigationController else { return }
        node.mnz_showVersions(in: nodeVersionNavigation)
    }
}

extension NodeInfoRouter: NodeInfoViewControllerDelegate {

    func nodeInfoViewController(
        _ nodeInfoViewController: NodeInfoViewController,
        presentParentNode node: MEGANode
    ) {
        node.navigateToParentAndPresent()
    }
}
