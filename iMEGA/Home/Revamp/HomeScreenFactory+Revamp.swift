import Home
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n

// MARK: - Revamped Home
extension HomeScreenFactory {
    func createRevampedHomeScreen(
        from tabBarController: MainTabBarController,
    ) -> UIViewController {

        let navigationController = MEGANavigationController()
        navigationController.tabBarItem = UITabBarItem(title: nil, image: MEGAAssets.UIImage.home, selectedImage: nil)

        let newChatRouter = NewChatRouter(
            navigationController: navigationController,
            tabBarController: tabBarController
        )

        let router = HomeViewRouter(navigationController: navigationController)
        let dependency = HomeView.Dependency(
            homeAddMenuActionHandler: makeHomeAddMenuActionHandler(newChatRouter: newChatRouter, navigationController: navigationController),
            router: router,
            fullNameHandler: { $0.currentUser?.mnz_fullName ?? "" }
        )
        
        let homeView = HomeView(dependency: dependency)

        let hostingController = HomeViewHostingController(rootView: homeView)

        navigationController.viewControllers = [hostingController]

        return navigationController
    }

    private func makeHomeAddMenuActionHandler(newChatRouter: NewChatRouter, navigationController: UINavigationController) -> HomeAddMenuActionHandler {
        let tracker = DIContainer.tracker
        let uploadAddMenuDelegateHandler = UploadAddMenuDelegateHandler(
            tracker: tracker,
            nodeInsertionRouter: makeCloudDriveNodeInsertionRouter(navigationController: navigationController),
            nodeSource: .node { MEGASdk.sharedSdk.rootNode?.toNodeEntity() }
        )

        return HomeAddMenuActionHandler(
            uploadAddMenuDelegateHandler: uploadAddMenuDelegateHandler,
            newChatRouter: newChatRouter,
            navigationController: navigationController
        )
    }

    private func makeCloudDriveNodeInsertionRouter(navigationController: UINavigationController) -> CloudDriveNodeInsertionRouter {
        CloudDriveNodeInsertionRouter(navigationController: navigationController, openNodeHandler: { _ in })
    }
}

@MainActor
private struct HomeAddMenuActionHandler: HomeAddMenuActionHandling {

    private let uploadAddMenuDelegateHandler: UploadAddMenuDelegateHandler
    private let newChatRouter: NewChatRouter
    private unowned let navigationController: UINavigationController

    init(
        uploadAddMenuDelegateHandler: UploadAddMenuDelegateHandler,
        newChatRouter: NewChatRouter,
        navigationController: UINavigationController
    ) {
        self.uploadAddMenuDelegateHandler = uploadAddMenuDelegateHandler
        self.newChatRouter = newChatRouter
        self.navigationController = navigationController
    }

    func handleAction(_ action: HomeAddMenuAction) {
        switch action {
        case .chooseFromPhotos:
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .chooseFromPhotos)
        case .capture:
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .capture)
        case .importFromFiles:
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .importFrom)
        case .scanDocument:
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .scanDocument)
        case .newTextFile:
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .newTextFile)
        case .newChat:
            newChatRouter.presentNewChat(from: navigationController)
        }
    }
}
