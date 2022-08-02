import Foundation

final class HomeSearchResultRouter {

    private weak var navigationController: UINavigationController?

    private var nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate

    private lazy var nodeOpener = NodeOpener(navigationController: navigationController)

    init(
        navigationController: UINavigationController,
        nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate
    ) {
        self.navigationController = navigationController
        self.nodeActionViewControllerDelegate = nodeActionViewControllerDelegate
    }

    func didTapMoreAction(on node: HandleEntity, button: UIButton) {
        guard let nodeActionViewController = NodeActionViewController(
            node: node,
            delegate: nodeActionViewControllerDelegate,
            displayMode: .cloudDrive,
            isIncoming: false,
            sender: button
        ) else { return }
        navigationController?.present(nodeActionViewController, animated: true, completion: nil)
    }

    func didTapNode(_ nodeHandle: HandleEntity) {
        nodeOpener.openNode(nodeHandle)
    }
}
