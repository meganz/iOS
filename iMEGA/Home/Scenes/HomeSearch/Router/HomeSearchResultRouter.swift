import Foundation
import MEGADomain

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
        Task {
            let myBackupsUC = MyBackupsUseCase(myBackupsRepository: MyBackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo, nodeValidationRepository: NodeValidationRepository.newRepo)
            let isBackupNode = await myBackupsUC.isBackupNodeHandle(node)
            guard let nodeActionViewController = await NodeActionViewController(
                node: node,
                delegate: nodeActionViewControllerDelegate,
                displayMode: .cloudDrive,
                isIncoming: false,
                isBackupNode: isBackupNode,
                sender: button
            ) else { return }
            await navigationController?.present(nodeActionViewController, animated: true, completion: nil)
        }
    }

    func didTapNode(_ nodeHandle: HandleEntity) {
        nodeOpener.openNode(nodeHandle)
    }
}
