import MEGADomain
import MEGAPhotos
import UIKit

final class PhotoSearchResultRouter: PhotoSearchResultRouterProtocol {
    private weak var navigationController: UINavigationController?
    private let nodeActionViewControllerDelegate: any NodeActionViewControllerDelegate
    private let backupsUseCase: any BackupsUseCaseProtocol
    
    private lazy var nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    
    init(
        navigationController: UINavigationController?,
        nodeActionViewControllerDelegate: any NodeActionViewControllerDelegate,
        backupsUseCase: any BackupsUseCaseProtocol
    ) {
        self.navigationController = navigationController
        self.nodeActionViewControllerDelegate = nodeActionViewControllerDelegate
        self.backupsUseCase = backupsUseCase
    }
    
    func didTapMoreAction(on node: HandleEntity, button: UIButton) {
        let isBackupNode = backupsUseCase.isBackupNodeHandle(node)
        guard let nodeActionViewController = NodeActionViewController(
            node: node,
            delegate: nodeActionViewControllerDelegate,
            displayMode: .cloudDrive,
            isIncoming: false,
            isBackupNode: isBackupNode,
            isFromSharedItem: false,
            sender: button
        ) else { return }
        nodeActionViewController.accessoryActionDelegate = nodeAccessoryActionDelegate
        navigationController?.present(nodeActionViewController, animated: true, completion: nil)
    }
}
