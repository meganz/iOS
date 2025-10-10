import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGARepo
import SwiftUI

final class NameCollisionViewRouter: NameCollisionViewRouting {
    
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private weak var viewModel: NameCollisionViewModel?

    private let transfers: [CancellableTransfer]?
    private let nodes: [NodeEntity]?
    private let collisions: [NameCollisionEntity]
    private let collisionType: NameCollisionType
    private let isFolderLink: Bool
    private let copyOrMoveCompletion: (() -> Void)?

    init(
        presenter: UIViewController,
        transfers: [CancellableTransfer]?,
        nodes: [NodeEntity]?,
        collisions: [NameCollisionEntity],
        collisionType: NameCollisionType,
        isFolderLink: Bool = false,
        copyOrMoveCompletion: (() -> Void)? = nil
    ) {
        self.presenter = presenter
        self.transfers = transfers
        self.nodes = nodes
        self.collisions = collisions
        self.collisionType = collisionType
        self.isFolderLink = isFolderLink
        self.copyOrMoveCompletion = copyOrMoveCompletion
    }
    
    func build() -> UIViewController {
        let viewModel = NameCollisionViewModel(
            router: self,
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            nameCollisionUseCase: NameCollisionUseCase(nodeRepository: NodeRepository.newRepo, nodeActionsRepository: NodeActionsRepository.newRepo, nodeDataRepository: NodeDataRepository.newRepo, fileSystemRepository: FileSystemRepository.sharedRepo),
            fileVersionsUseCase: FileVersionsUseCase(repo: FileVersionsRepository.newRepo),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
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

    @MainActor
    func showCopyOrMoveSuccess() async {
        dismiss()
        SVProgressHUD.showSuccess(withStatus: Strings.Localizable.completed)
        copyOrMoveCompletion?()
    }

    @MainActor
    func showCopyOrMove(error: (any Error)?) async {
        guard
            let nodeCopyOrMoveError = error as? CopyOrMoveErrorEntity,
            nodeCopyOrMoveError != .overQuota
        else {
            return
        }

        dismiss()

        if nodeCopyOrMoveError == .nodeMoveFailedCircularLinkage {
            SVProgressHUD.showError(withStatus: Strings.Localizable.Error.NodeCopyOrMove.circularDependency)
        } else {
            SVProgressHUD.showError(withStatus: Strings.Localizable.somethingWentWrong)
        }
    }
    
    func showProgressIndicator() {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
    }
}
