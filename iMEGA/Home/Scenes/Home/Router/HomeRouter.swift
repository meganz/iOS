import CoreServices
import MEGADomain
import MEGASDKRepo
import UIKit

@MainActor
protocol HomeRouterProtocol {

    func didTap(on source: HomeRoutingSource, with object: Any?)
    
    func showNode(_ base64Handle: Base64HandleEntity)
    
    func showDownloadTransfer(node: MEGANode)
}

enum HomeRoutingSource {

    // MARK: - Navigation Bar Button

    case avatar
    case uploadButton
    case newChat

    // MARK: - Application Root Launcher

    case showAchievement

    // MARK: - Recents

    case nodeCustomActions(MEGANode)
    case node(MEGANode)

    // MARK: - Node Actions

    case fileInfo(MEGANode)
    case linkManagement(MEGANode)
    case removeLink(MEGANode)
    case copy(MEGANode)
    case move(MEGANode)
    case delete(MEGANode)
    case exportFile(MEGANode, Any)
    case shareFolder(MEGANode)
    case manageShare(MEGANode)
    case setLabel(MEGANode)
    case editTextFile(MEGANode)
    case viewTextFileVersions(MEGANode)
    case hide(MEGANode)
    case unhide(MEGANode)
}

final class HomeRouter: HomeRouterProtocol {

    // MARK: - Navigations

    private weak var navigationController: UINavigationController?

    private weak var tabBarController: MainTabBarController?

    // MARK: - Sub-router

    private let newChatRouter: NewChatRouter

    // MARK: - Node Action Routers

    private let nodeActionRouter: RecentNodeRouter

    private let nodeInfoRouter: NodeInfoRouter

    private let nodeLinkManagementRouter: NodeLinkRouter

    private let nodeManageRouter: NodeManagementRouter

    private let nodeShareRouter: NodeShareRouter

    // MARK: - Lifecycles

    init(navigationController: UINavigationController?, tabBarController: MainTabBarController) {
        assert(navigationController != nil, "Must pass in a UINavigationController in HomeRouter.")
        self.navigationController = navigationController
        self.newChatRouter = NewChatRouter(navigationController: navigationController, tabBarController: tabBarController)
        self.nodeActionRouter = RecentNodeRouter(navigationController: navigationController)
        self.nodeInfoRouter = NodeInfoRouter(navigationController: navigationController, contacstUseCase: ContactsUseCase(repository: ContactsRepository.newRepo))
        self.nodeLinkManagementRouter = NodeLinkRouter(navigationController: navigationController)
        self.nodeManageRouter = NodeManagementRouter(navigationController: navigationController)
        self.nodeShareRouter = NodeShareRouter(viewController: navigationController)
    }

    func didTap(on source: HomeRoutingSource, with object: Any? = nil) {
        switch source {

        case .avatar:
            routeToAccount(with: navigationController)
        case .uploadButton:
            presentUploadOptionActionSheet(from: navigationController, withActionItems: object as! [ActionSheetAction])
        // MARK: - New Chat

        case .newChat:
            newChatRouter.presentNewChat(from: navigationController)

        // MARK: - Application

        case .showAchievement:
            presentAchievement()

        // MARK: - Recents

        case .nodeCustomActions(let node):
            nodeActionRouter.didTap(.nodeActions(node), object: object)
        case .node:
            break

        // MARK: - Node Actions

        case .fileInfo(let node):
            nodeInfoRouter.showInformation(for: node)
        case .viewTextFileVersions(let node):
            nodeInfoRouter.showVersions(for: node)
        case .linkManagement(let node):
            nodeLinkManagementRouter.showLinkManagement(for: node)
        case .removeLink(let node):
            
            guard let navigationController else { return }
            
           let router = ActionWarningViewRouter(presenter: navigationController, nodes: [node.toNodeEntity()], actionType: .removeLink, onActionStart: {
                SVProgressHUD.show()
            }, onActionFinish: {
                switch $0 {
                case .success(let message):
                    SVProgressHUD.showSuccess(withStatus: message)
                case .failure:
                    SVProgressHUD.dismiss()
                }
            })
            router.start()
        // MARK: - Node Copy & Move & Delete & Edit
        case .copy(let node):
            nodeManageRouter.showCopyDestination(for: node)
        case .move(let node):
            nodeManageRouter.showMoveDestination(for: node)
        case .delete(let node):
            nodeManageRouter.showMoveToRubbishBin(for: node)
        case .setLabel(let node):
            nodeManageRouter.showLabelColorAction(for: node)
        case .editTextFile(let node):
            nodeManageRouter.showEditTextFile(for: node)

        // MARK: - Share
        case .exportFile(let node, let sender):
            nodeShareRouter.exportFile(from: node, sender: sender)
        case .shareFolder(let node):
            nodeShareRouter.showSharingFolder(for: node)
        case .manageShare(let node):
            nodeShareRouter.showManageSharing(for: node)
        case .hide(let node):
            HideFilesAndFoldersRouter(presenter: navigationController)
                .hideNodes([node.toNodeEntity()])
        case .unhide(let node):
            let nodeActionUseCase = NodeActionUseCase(repo: NodeActionRepository.newRepo)
            Task {
                _ = await nodeActionUseCase.unhide(nodes: [node].toNodeEntities())
            }
        }
    }
    
    func showNode(_ base64Handle: Base64HandleEntity) {
        navigationController?.popToRootViewController(animated: false)
        let handle = MEGASdk.handle(forBase64Handle: base64Handle)
        NodeOpener(navigationController: navigationController)
            .openNode(nodeHandle: handle)
    }
    
    func showDownloadTransfer(node: MEGANode) {
        guard let navigationController = navigationController else {
            return
        }
        
        let transfer = CancellableTransfer(handle: node.handle, name: nil, appData: nil, priority: false, isFile: node.isFile(), type: .download)
        CancellableTransferRouter(presenter: navigationController, transfers: [transfer], transferType: .download).start()
    }

    // MARK: - Show Favourites Explorer View Controller
    
    func favouriteExplorerSelected() {
        FilesExplorerRouter(navigationController: navigationController, explorerType: .favourites).start()
    }
    
    // MARK: - Show Documents Explorer View Controller
    
    func documentsExplorerSelected() {
        FilesExplorerRouter(navigationController: navigationController, explorerType: .allDocs).start()
    }
    
    // MARK: - Show Audio Explorer View Controller
    
    func audioExplorerSelected() {
        FilesExplorerRouter(navigationController: navigationController, explorerType: .audio).start()
    }
    
    // MARK: - Show Audio Explorer View Controller
    
    func videoExplorerSelected() {
        FilesExplorerRouter(navigationController: navigationController, explorerType: .video).start()
    }
    
    // MARK: - Show Account View Controller

    private func routeToAccount(with navigationController: UINavigationController?) {
        guard let navigationController else {
            return
        }
        
        MyAccountHallRouter(
            myAccountHallUseCase: MyAccountHallUseCase(repository: AccountRepository.newRepo),
            purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            shareUseCase: makeShareUseCase(),
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            notificationsUseCase: NotificationsUseCase(repository: NotificationsRepository.newRepo),
            navigationController: navigationController
        ).start()
    }

    // MARK: - Display Upload Source Selection Action Sheet

    private func presentUploadOptionActionSheet(
        from navigationController: UINavigationController?,
        withActionItems actions: [ActionSheetAction]
    ) {
        let actionSheetViewController = ActionSheetViewController(actions: actions,
                                                                  headerTitle: nil,
                                                                  dismissCompletion: nil,
                                                                  sender: nil)
        navigationController?.present(actionSheetViewController, animated: true, completion: nil)
    }

    // MARK: - Display Application Event

    private func presentAchievement() {
        guard let navigationController else {
            return
        }
        
        MyAccountHallRouter(
            myAccountHallUseCase: MyAccountHallUseCase(repository: AccountRepository.newRepo),
            purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            shareUseCase: makeShareUseCase(),
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            notificationsUseCase: NotificationsUseCase(repository: NotificationsRepository.newRepo),
            shouldOpenAchievements: true,
            navigationController: navigationController
        ).start()
    }
    
    private func makeShareUseCase() -> some ShareUseCaseProtocol {
        ShareUseCase(
            shareRepository: ShareRepository.newRepo,
            filesSearchRepository: FilesSearchRepository.newRepo,
            nodeRepository: NodeRepository.newRepo)
    }
}
