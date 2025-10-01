import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGAPreference

// This protocol was added to enable both new and legacy Cloud Drive screen use the same navigation mechanism
// using NodeOpener to drill deeper into folders or files, and also use the same for context menu presentation
@MainActor
protocol NodeRouting {
    func didTapMoreAction(
        on node: HandleEntity,
        button: UIButton,
        isFromSharedItem: Bool
    )
    
    func didTapMoreAction(
        on node: HandleEntity,
        button: UIButton,
        displayMode: DisplayMode?,
        isFromSharedItem: Bool
    )

    func didTapNode(nodeHandle: HandleEntity, allNodeHandles: [HandleEntity]?, displayMode: DisplayMode?, isFromSharedItem: Bool, warningViewModel: WarningBannerViewModel?)

    func didTapNode(nodeHandle: HandleEntity, allNodeHandles: [HandleEntity]?)
    
    func didTapNode(nodeHandle: HandleEntity)

    /// Opens the user's profile screen.
    ///
    /// This method is called when the user taps their avatar (at the top left of the screen
    /// or on the left side of the navigation bar).
    func openUserProfile()
}

final class HomeSearchResultRouter: NodeRouting {
    
    private weak var navigationController: UINavigationController?
    
    private var nodeActionViewControllerDelegate: any NodeActionViewControllerDelegate
    
    private lazy var nodeOpener = NodeOpener(navigationController: navigationController)
    private lazy var nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    
    private let backupsUseCase: any BackupsUseCaseProtocol
    
    private let nodeUseCase: any NodeUseCaseProtocol
    
    init(
        navigationController: UINavigationController,
        nodeActionViewControllerDelegate: some NodeActionViewControllerDelegate,
        backupsUseCase: some BackupsUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol
    ) {
        self.navigationController = navigationController
        self.nodeActionViewControllerDelegate = nodeActionViewControllerDelegate
        self.backupsUseCase = backupsUseCase
        self.nodeUseCase = nodeUseCase
    }
    
    func didTapMoreAction(
        on node: HandleEntity,
        button: UIButton,
        isFromSharedItem: Bool
    ) {
        didTapMoreAction(on: node, button: button, displayMode: nil, isFromSharedItem: isFromSharedItem)
    }
    
    func didTapMoreAction(
        on node: HandleEntity,
        button: UIButton,
        displayMode: DisplayMode?,
        isFromSharedItem: Bool
    ) {
        let isBackupNode = backupsUseCase.isBackupNodeHandle(node)
        guard let nodeActionViewController = NodeActionViewController(
            node: node,
            delegate: nodeActionViewControllerDelegate,
            displayMode: displayMode ?? .cloudDrive,
            isIncoming: false,
            isBackupNode: isBackupNode,
            isFromSharedItem: isFromSharedItem,
            isSelectionEnabled: DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .cloudDriveRevamp),
            sender: button
        ) else { return }
        nodeActionViewController.accessoryActionDelegate = nodeAccessoryActionDelegate
        navigationController?.present(nodeActionViewController, animated: true, completion: nil)
    }
    
    func didTapNode(nodeHandle: HandleEntity, allNodeHandles: [HandleEntity]?, displayMode: DisplayMode?, isFromSharedItem: Bool, warningViewModel: WarningBannerViewModel? = nil) {
        Task {
            guard let node = await nodeUseCase.nodeForHandle(nodeHandle) else { return }
            if node.isFile, node.isTakenDown {
                showTakenDownAlert()
            } else {
                nodeOpener.openNode(
                    nodeHandle: nodeHandle,
                    allNodes: allNodeHandles,
                    config: .init(
                        displayMode: displayMode,
                        isFromSharedItem: isFromSharedItem,
                        warningViewModel: warningViewModel)
                )
            }
        }
    }
    
    func didTapNode(nodeHandle: HandleEntity, allNodeHandles: [HandleEntity]?) {
        didTapNode(nodeHandle: nodeHandle, allNodeHandles: allNodeHandles, displayMode: nil, isFromSharedItem: false)
    }
    
    func didTapNode(nodeHandle: HandleEntity) {
        didTapNode(nodeHandle: nodeHandle, allNodeHandles: nil, displayMode: nil, isFromSharedItem: false)
    }
    
    func showTakenDownAlert() {
        let alert = UIAlertController(model: AlertModelFactory.makeTakenDownModel())
        navigationController?.present(alert, animated: true)
    }

    func openUserProfile() {
        guard let navigationController else {
            assertionFailure("Navigation controller not found")
            return
        }

        MyAccountHallRouter(
            myAccountHallUseCase: MyAccountHallUseCase(repository: AccountRepository.newRepo),
            purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            accountStorageUseCase: AccountStorageUseCase(
                accountRepository: AccountRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default
            ),
            shareUseCase: ShareUseCase(
                shareRepository: ShareRepository.newRepo,
                filesSearchRepository: FilesSearchRepository.newRepo,
                nodeRepository: NodeRepository.newRepo),
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            notificationsUseCase: NotificationsUseCase(repository: NotificationsRepository.newRepo),
            navigationController: navigationController
        ).start()
    }
}
