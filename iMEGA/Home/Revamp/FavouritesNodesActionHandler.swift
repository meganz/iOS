import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

@MainActor
struct FavouritesNodesActionHandler: NodesActionHandling {
    private weak var navigationController: UINavigationController?
    private let nodeUseCase: any NodeUseCaseProtocol
    private let favouriteUseCase: any NodeFavouriteActionUseCaseProtocol
    private let backupsUseCase: any BackupsUseCaseProtocol
    private let sdk: MEGASdk

    init(
        navigationController: UINavigationController,
        nodeUseCase: some NodeUseCaseProtocol,
        favouriteUseCase: any NodeFavouriteActionUseCaseProtocol,
        backupsUseCase: some BackupsUseCaseProtocol,
        sdk: MEGASdk
    ) {
        self.navigationController = navigationController
        self.nodeUseCase = nodeUseCase
        self.favouriteUseCase = favouriteUseCase
        self.backupsUseCase = backupsUseCase
        self.sdk = sdk
    }

    func handle(action: NodesAction) {
        switch action {
        case .download(let handles):
            download(nodeHandles: handles)
        case .shareLink(let handles):
            shareLink(for: handles)
        case .moveToRubbishBin(let handles):
            moveToRubbishBin(nodeHandles: handles)
        case .more(let handles):
            showMore(for: handles)
        case .toggleFavourites(let handles):
            toggleFavourites(for: handles)
        }
    }

    func handle(action: MEGAAppPresentation.NodeAction) {
        guard let navigationController else { return }
        let backupsUseCase = BackupsUseCase(
            backupsRepository: BackupsRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
        let isBackupNode = backupsUseCase.isBackupNodeHandle(action.handle)
        let delegate = NodeActionViewControllerGenericDelegate(
            viewController: navigationController,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: navigationController)
        )
        guard let nodeActionViewController = NodeActionViewController(
            node: action.handle,
            delegate: delegate,
            displayMode: .cloudDrive,
            isIncoming: false,
            isBackupNode: isBackupNode,
            isFromSharedItem: false,
            sender: action.sender
        ) else {
            return
        }
        
        navigationController.present(nodeActionViewController, animated: true)
    }

    private func download(nodeHandles: Set<HandleEntity>) {
        guard let navigationController, let nodes = nodes(from: nodeHandles) else { return }

        let transfers = nodes.map {
            CancellableTransfer(
                handle: $0.handle,
                name: $0.name,
                appData: nil,
                priority: false,
                isFile: $0.isFile,
                type: .download
            )
        }
        CancellableTransferRouter(
            presenter: navigationController,
            transfers: transfers,
            transferType: .download
        ).start()
    }

    private func shareLink(for nodeHandles: Set<HandleEntity>) {
        guard let navigationController, let nodes = nodes(from: nodeHandles) else { return }
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            GetLinkRouter(presenter: navigationController, nodes: nodes.toMEGANodes(in: sdk)).start()
        }

    }

    private func moveToRubbishBin(nodeHandles: Set<HandleEntity>) {
        guard let nodes = nodes(from: nodeHandles), let rubbishBinNode = sdk.rubbishNode else { return }

        let moveRequestDelegate = MEGAMoveRequestDelegate(
            toMoveToTheRubbishBinWithFiles: UInt(nodes.count),
            folders: 0
        ) { }
        nodes
            .compactMap { $0.toMEGANode(in: sdk) }
            .forEach { sdk.move($0, newParent: rubbishBinNode, delegate: moveRequestDelegate) }

    }

    private func toggleFavourites(for nodeHandles: Set<HandleEntity>) {
        guard let nodes = nodes(from: nodeHandles) else { return }

        nodes
            .compactMap { $0.toMEGANode(in: sdk) }
            .forEach { node in
                if node.isFavourite {
                    Task { try await favouriteUseCase.unFavourite(node: node.toNodeEntity()) }
                } else {
                    Task { try await favouriteUseCase.favourite(node: node.toNodeEntity()) }
                }
            }
    }

    private func showMore(for nodeHandles: Set<HandleEntity>) {
        guard let navigationController, let nodes = nodes(from: nodeHandles) else { return }

        let delegate = NodeActionViewControllerGenericDelegate(
            viewController: navigationController,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: navigationController)
        )
        let nodeActionsViewController = NodeActionViewController(
            nodes: nodes.compactMap { $0.toMEGANode(in: sdk) },
            delegate: delegate,
            displayMode: .cloudDrive,
            containsABackupNode: backupsUseCase.hasBackupNode(in: nodes),
            sender: navigationController.view as Any
        )
        navigationController.present(nodeActionsViewController, animated: true)
    }

    private func nodes(from handles: Set<HandleEntity>) -> [NodeEntity]? {
        let nodes = handles.compactMap(nodeUseCase.nodeForHandle)
        guard nodes.isNotEmpty else { return nil }
        return nodes
    }
}
