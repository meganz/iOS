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

        let menuActions = makeRevampMenuActions(newChatRouter: newChatRouter, navigationController: navigationController)
        let menuActionsSheetViewModel = HomeMenuActionsSheetViewModel(menuActions: menuActions)
        let homeView = HomeView(
            menuActionsSheetViewModel: menuActionsSheetViewModel
        )

        let hostingController = HomeViewHostingController(rootView: homeView)

        navigationController.viewControllers = [hostingController]

        return navigationController
    }

    private func makeRevampMenuActions(
        newChatRouter: NewChatRouter,
        navigationController: UINavigationController
    ) -> [HomeMenuAction] {

        let tracker = DIContainer.tracker
        let uploadAddMenuDelegateHandler = UploadAddMenuDelegateHandler(
            tracker: tracker,
            nodeInsertionRouter: makeCloudDriveNodeInsertionRouter(navigationController: navigationController),
            nodeSource: .node { MEGASdk.sharedSdk.rootNode?.toNodeEntity() }
        )

        let chooseFromPhotos = HomeMenuAction(image: MEGAAssets.Image.photosApp, title: Strings.Localizable.choosePhotoVideo) {
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .chooseFromPhotos)
        }

        let capture = HomeMenuAction(image: MEGAAssets.Image.camera, title: Strings.Localizable.capturePhotoVideo) {
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .capture)
        }

        let importFromFiles = HomeMenuAction(image: MEGAAssets.Image.folderArrow, title: Strings.Localizable.CloudDrive.Upload.importFromFiles) {
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .importFrom)
        }

        let scanDocument = HomeMenuAction(image: MEGAAssets.Image.fileScan, title: Strings.Localizable.scanDocument) {
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .scanDocument)
        }

        let newTextFile = HomeMenuAction(image: MEGAAssets.Image.filePlus02, title: Strings.Localizable.newTextFile) {
            uploadAddMenuDelegateHandler.uploadAddMenu(didSelect: .newTextFile)
        }

        let newChat = HomeMenuAction(image: MEGAAssets.Image.messageChatCircle, title: Strings.Localizable.Chat.NewChat.title) {
            newChatRouter.presentNewChat(from: navigationController)
        }

        return [chooseFromPhotos, capture, importFromFiles, scanDocument, newTextFile, newChat]
    }

    private func makeCloudDriveNodeInsertionRouter(navigationController: UINavigationController) -> CloudDriveNodeInsertionRouter {
        CloudDriveNodeInsertionRouter(navigationController: navigationController, openNodeHandler: { _ in })
    }
}
