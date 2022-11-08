import Foundation
import MEGADomain

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

    private func presentAction(for node: MEGANode, in navigationController: UINavigationController?) async {
        let myBackupsUC = MyBackupsUseCase(myBackupsRepository: MyBackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo, nodeValidationRepository: NodeValidationRepository.newRepo)
        let isBackupNode = await myBackupsUC.isBackupNode(node.toNodeEntity())
        let nodeActionViewController = await NodeActionViewController(
            node: node,
            delegate: self,
            displayMode: .recents,
            isIncoming: false,
            isBackupNode: isBackupNode,
            sender: self
        )
        await navigationController?.present(nodeActionViewController, animated: true, completion: nil)
    }

    // MARK: - Routing

    func didTap(_ source: RecentNodeSource, object: Any?) {
        switch source {
        case .nodeActions(let node):
            Task {
                completionAction = (object as! (MEGANode, MegaNodeActionType) -> Void)
                await presentAction(for: node, in: navigationController)
            }
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
