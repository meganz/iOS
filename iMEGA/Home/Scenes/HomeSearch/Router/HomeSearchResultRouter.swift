import Foundation
import MEGADomain
import MEGASDKRepo

// This protocol was added to enable both new and legacy Cloud Drive screen use the same navigation mechanism
// using NodeOpener to drill deeper into folders or files, and also use the same for context menu presentation
protocol NodeRouting {
    func didTapMoreAction(
        on node: HandleEntity,
        button: UIButton
    )
    func didTapNode(_ nodeHandle: HandleEntity)
}

final class HomeSearchResultRouter: NodeRouting {

    private weak var navigationController: UINavigationController?

    private var nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate

    private lazy var nodeOpener = NodeOpener(navigationController: navigationController)
    
    private let backupsUseCase: any BackupsUseCaseProtocol

    init(
        navigationController: UINavigationController,
        nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate,
        backupsUseCase: some BackupsUseCaseProtocol
    ) {
        self.navigationController = navigationController
        self.nodeActionViewControllerDelegate = nodeActionViewControllerDelegate
        self.backupsUseCase = backupsUseCase
    }
    
    func didTapMoreAction(
        on node: HandleEntity,
        button: UIButton
    ) {
        let isBackupNode = backupsUseCase.isBackupNodeHandle(node)
        guard let nodeActionViewController = NodeActionViewController(
            node: node,
            delegate: nodeActionViewControllerDelegate,
            displayMode: .cloudDrive,
            isIncoming: false,
            isBackupNode: isBackupNode,
            sender: button
        ) else { return }
        navigationController?.present(nodeActionViewController, animated: true, completion: nil)
    }

    func didTapNode(_ nodeHandle: HandleEntity) {
        nodeOpener.openNode(nodeHandle)
    }
}
