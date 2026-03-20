import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

@MainActor
final class RecentActionBucketMoreActionsPresenter: MoreNodeActionsPresenting {
    private weak var navigationController: UINavigationController?
    private let nodeUseCase: any NodeUseCaseProtocol
    private let backupsUseCase: any BackupsUseCaseProtocol
    private let sdk: MEGASdk

    init(
        navigationController: UINavigationController,
        nodeUseCase: some NodeUseCaseProtocol,
        backupsUseCase: some BackupsUseCaseProtocol,
        sdk: MEGASdk
    ) {
        self.navigationController = navigationController
        self.nodeUseCase = nodeUseCase
        self.backupsUseCase = backupsUseCase
        self.sdk = sdk
    }

    func presentActions(for handles: Set<HandleEntity>, completion: @escaping () -> Void) {
        guard let navigationController else { return }
        let nodes = handles.compactMap(nodeUseCase.nodeForHandle)
        guard nodes.isNotEmpty else { return }

        let delegate = NodeActionViewControllerGenericDelegate(
            viewController: navigationController,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: navigationController),
            nodeActionListener: { _, _ in
                completion()
            }
        )
        let nodeActionsViewController = NodeActionViewController(
            nodes: nodes.compactMap { $0.toMEGANode(in: sdk) },
            delegate: delegate,
            displayMode: .recents,
            containsABackupNode: backupsUseCase.hasBackupNode(in: nodes),
            sender: navigationController.view as Any
        )
        navigationController.present(nodeActionsViewController, animated: true)
    }
}
