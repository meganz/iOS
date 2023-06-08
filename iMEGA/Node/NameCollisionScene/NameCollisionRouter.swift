import SwiftUI
import MEGADomain
import MEGAData

final class NameCollisionViewRouter: NameCollisionViewRouting {
    
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private weak var viewModel: NameCollisionViewModel?

    private let transfers: [CancellableTransfer]?
    private let nodes: [NodeEntity]?
    private let collisions: [NameCollisionEntity]
    private let collisionType: NameCollisionType
    private let isFolderLink: Bool

    init(presenter: UIViewController, transfers: [CancellableTransfer]?, nodes: [NodeEntity]?, collisions: [NameCollisionEntity], collisionType: NameCollisionType, isFolderLink: Bool = false) {
        self.presenter = presenter
        self.transfers = transfers
        self.nodes = nodes
        self.collisions = collisions
        self.collisionType = collisionType
        self.isFolderLink = isFolderLink
    }
    
    func build() -> UIViewController {
        let viewModel = NameCollisionViewModel(
            router: self,
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            nameCollisionUseCase: NameCollisionUseCase(nodeRepository: NodeRepository.newRepo, nodeActionsRepository: NodeActionsRepository.newRepo, nodeDataRepository: NodeDataRepository.newRepo, fileSystemRepository: FileSystemRepository.newRepo),
            fileVersionsUseCase: FileVersionsUseCase(repo: FileVersionsRepository.newRepo),
            transfers: transfers,
            nodes: nodes,
            collisions: collisions,
            collisionType: collisionType,
            isFolderLink: isFolderLink
        )
        self.viewModel = viewModel
        let nameCollisionView = NameCollisionView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: nameCollisionView)
        
        return hostingController
    }
    
    func start() {
        let viewController = build()
        baseViewController = viewController
        viewModel?.checkNameCollisions()
    }
    
    func dismiss() {
        SVProgressHUD.setDefaultMaskType(.none)
        SVProgressHUD.dismiss()
        baseViewController?.dismiss(animated: true)
    }
    
    func showNameCollisionsView() {
        guard let baseViewController = baseViewController else {
            return
        }
        presenter?.present(baseViewController, animated: true)
    }
    
    func resolvedUploadCollisions(_ transfers: [CancellableTransfer]) {
        guard let presenter = presenter else {
            return
        }
        presenter.dismiss(animated: true) {
#if MNZ_SHARE_EXTENSION
            ShareExtensionCancellableTransferRouter(presenter: presenter, transfers: transfers).start()
#endif
#if MAIN_APP_TARGET
            CancellableTransferRouter(presenter: presenter, transfers: transfers, transferType: .upload).start()
#endif
        }
    }
    
    func showCopyOrMoveSuccess() {
        dismiss()
        SVProgressHUD.showSuccess(withStatus: Strings.Localizable.completed)
    }
    
    func showCopyOrMoveError() {
        dismiss()
        SVProgressHUD.showError(withStatus: Strings.Localizable.somethingWentWrong)
    }
    
    func showProgressIndicator() {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
    }
}
