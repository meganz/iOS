import MEGADomain
import MEGAPhotos
import UIKit

final class PhotoSearchResultRouter: PhotoSearchResultRouterProtocol {
    private weak var presenter: UIViewController?
    private let nodeActionViewControllerDelegate: any NodeActionViewControllerDelegate
    private let backupsUseCase: any BackupsUseCaseProtocol
    
    private lazy var nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    
    init(
        presenter: UIViewController?,
        nodeActionViewControllerDelegate: any NodeActionViewControllerDelegate,
        backupsUseCase: any BackupsUseCaseProtocol
    ) {
        self.presenter = presenter
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
        presenter?.present(nodeActionViewController, animated: true, completion: nil)
    }
    
    func didSelectAlbum(_ album: AlbumEntity) {
        let navigationController = MEGANavigationController()
        let router = AlbumContentRouter(navigationController: navigationController, album: album, newAlbumPhotos: nil)
        navigationController.setViewControllers([router.build()], animated: false)
        navigationController.modalPresentationStyle = .fullScreen
        presenter?.present(navigationController, animated: true, completion: nil)
    }
    
    func didSelectPhoto(_ photo: NodeEntity, otherPhotos: [NodeEntity]) {
        PhotoLibraryContentViewRouter()
            .openPhotoBrowser(for: photo, allPhotos: otherPhotos)
    }
}
