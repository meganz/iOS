import Favourites
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
            fileSearchUseCase: fileSearchUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            favouritesSearchResultsMapper: makeFavouritesSearchResultsMapper(with: navigationController),
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

    private func makeFavouritesSearchResultsMapper(
        with navigationController: UINavigationController
    ) -> some FavouritesSearchResultsMapping {
        SearchResultMapper(
            sdk: MEGASdk.sharedSdk,
            nodeIconUsecase: NodeIconUseCase(nodeIconRepo: NodeAssetsManager.shared),
            nodeDetailUseCase: NodeDetailUseCase(
                sdkNodeClient: .live,
                nodeThumbnailHomeUseCase: NodeThumbnailHomeUseCase(
                    sdkNodeClient: .live,
                    fileSystemClient: .live,
                    thumbnailRepo: ThumbnailRepository.newRepo
                )
            ),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(
                    repository: AccountRepository.newRepo)
            ),
            mediaUseCase: MediaUseCase(
                fileSearchRepo: FilesSearchRepository.newRepo,
                videoMediaUseCase: VideoMediaUseCase(videoMediaRepository: VideoMediaRepository.newRepo)
            ),
            nodeActions: NodeActions.makeActions(
                sdk: MEGASdk.sharedSdk,
                navigationController: navigationController
            ),
            hiddenNodesFeatureEnabled: DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
        )
    }

    private var fileSearchUseCase: some FilesSearchUseCaseProtocol {
        FilesSearchUseCase(
            repo: FilesSearchRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
    }

    private var sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol {
        SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(
                    repository: AccountRepository.newRepo)
            ),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) }
        )
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

// Ideally, Favourites should own its own mapping logic so the main target doesn't depend on the Favourites package.
//
// Current blockers:
// `swipeActions: @escaping @Sendable (ViewDisplayMode) -> [SearchResultSwipeAction]` is hard to implement in favourties because of navigation
// `info(for node: NodeEntity) -> @Sendable (ResultCellLayout) -> String` makes use of Helper
// `properties(for node: NodeEntity) -> [ResultProperty]` need to think about refactoring and reusing this implementation
//
// To remove this dependency, refactor `SearchResultMapper` and `SearchResult`.
// Note: This may be time-consuming, which is why we currently keep the import.
//
// Future consideration:
// Most fields come from `NodeEntity` with some customization. We could introduce a protocol (instead of `SearchResult`)
// and let each client construct its own model.
extension SearchResultMapper: FavouritesSearchResultsMapping { }
