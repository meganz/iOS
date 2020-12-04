import Foundation

final class RecentNodeRouter {

    private weak var navigationController: UINavigationController?

    private var completionAction: ((MEGANode, MegaNodeActionType) -> Void)?

    // MARK: - Lifecycles

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    enum RecentNodeSource {
        case nodeActions(MEGANode)
        case node
    }

    private func presentAction(for node: MEGANode, in navigationController: UINavigationController?) {
        let nodeActionViewController = NodeActionViewController(
            node: node,
            delegate: self,
            displayMode: .recents,
            isIncoming: false,
            sender: self
        )
        nodeActionViewController.shouldAutorotateScreen = false
        navigationController?.present(nodeActionViewController, animated: true, completion: nil)
    }

    // MARK: - Routing

    func didTap(_ source: RecentNodeSource, object: Any?) {
        switch source {
        case .nodeActions(let node):
            completionAction = (object as! (MEGANode, MegaNodeActionType) -> Void)
            presentAction(for: node, in: navigationController)
        case .node:
            break
        }
    }
}

extension RecentNodeRouter: NodeActionViewControllerDelegate {

    func nodeAction(
        _ nodeAction: NodeActionViewController,
        didSelect action: MegaNodeActionType,
        for node: MEGANode,
        from sender: Any
    ) {
        completionAction?(node, action)
        completionAction = nil
    }
}
