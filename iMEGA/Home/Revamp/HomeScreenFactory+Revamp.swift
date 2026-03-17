import Combine
import Favourites
import Home
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAInfrastructure
import MEGAL10n
import MEGAPreference
import MEGARepo
import Search
import SwiftUI

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

        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository.newRepo,
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.sharedRepo
        )

        let fullNameHandler: @Sendable (CurrentUserSource) -> String = { $0.currentUser?.mnz_fullName ?? "" }
        let megaHandleUseCase = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)

        let nodeActionHandledSubject = PassthroughSubject<Void, Never>()
        let favouritesNodesActionHandler = FavouritesNodesActionHandler(
            navigationController: navigationController,
            nodeUseCase: nodeUseCase,
            favouriteUseCase: favouriteUseCase,
            backupsUseCase: backupsUseCase,
            sdk: MEGASdk.sharedSdk,
            nodeActionListener: { _, _ in nodeActionHandledSubject.send() }
        )

        let router = HomeViewRouter(navigationController: navigationController)

        let nodeRouter = HomeSearchResultRouter(
            navigationController: navigationController,
            nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate(
                viewController: navigationController,
                moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: navigationController)
            ),
            backupsUseCase: backupsUseCase,
            nodeUseCase: nodeUseCase
        )
        
        let searchResultsProvider = makeResultsProvider(
            parentNodeProvider: {[weak sdk] in sdk?.rootNode?.toNodeEntity() },
            navigationController: navigationController
        )
        
        let searchResultMapper = makeSearchResultMapper(with: navigationController)
        
        let dependency = HomeView.Dependency(
            homeAddMenuActionHandler: makeHomeAddMenuActionHandler(newChatRouter: newChatRouter, navigationController: navigationController),
            router: router,
            fullNameHandler: fullNameHandler,
            avatarFetcher: makeAvatarFetcher(
                fullNameHandler: fullNameHandler,
                userImageUseCase: userImageUseCase,
                megaHandleUseCase: megaHandleUseCase
            ),
            fileSearchUseCase: fileSearchUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            favouritesSearchResultsMapper: searchResultMapper,
            downloadedNodesListener: downloadedNodesListener,
            nodeUseCase: nodeUseCase,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            favouritesNodesActionHandler: favouritesNodesActionHandler,
            userNameProvider: HomeRecentUserNameProvider(),
            recentActionBucketItemResultMapper: searchResultMapper,
            onFavouritesEditingChanged: { [weak tabBarController] isEditing in
                tabBarController?.tabBar.isHidden = isEditing
            },
            favouritesNodeSelectionAction: FavouritesNodeSelectionHandler(nodeRouter: nodeRouter),
            onFavouritesNodeActionPerformed: nodeActionHandledSubject.eraseToAnyPublisher(),
            searchResultsProvider: searchResultsProvider,
            offlineFilesUseCase: offlineFilesUseCase,
            searchResultsSelectionHandler: HomeSearchNodeSelectionHandler(nodeRouter: nodeRouter),
            searchResultNodeActionHandler: HomeSearchNodesActionHandler(nodeRouter: nodeRouter),
            recentActionBucketNodeSelectionHandler: RecentActionBucketNodeSelectionHandler(nodeRouter: nodeRouter),
            recentActionBucketNodesActionHandler: RecentActionBucketNodesActionHandler(nodeRouter: nodeRouter)
        )
        
        let hostingController = HomeViewHostingController(dependency: dependency)
        
        navigationController.viewControllers = [hostingController]

        return navigationController
    }

    private func makeAvatarFetcher(
        fullNameHandler: @escaping @Sendable (CurrentUserSource) -> String,
        userImageUseCase: some UserImageUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol
    ) -> (@Sendable () async -> Image?) {
        return {
            let currentUserSource = CurrentUserSource.shared
            // Needs to be @MainActor because fullNameHandler access CoreData under the hood and
            let fullNameTask = Task { @MainActor in
                fullNameHandler(currentUserSource)
            }
            let fullName = await fullNameTask.value
            let handle = currentUserSource.currentUserHandle ?? 0

            guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: handle) else {
                MEGALogError("base64 handle not found for handle \(handle)")
                return nil
            }

            let backgroundColor = userImageUseCase.avatarColorHex(forBase64UserHandle: base64Handle)

            let avatarHandler = UserAvatarHandler(
                userImageUseCase: userImageUseCase,
                initials: fullName.initialForAvatar(),
                avatarBackgroundColor: UIColor.colorFromHexString(backgroundColor) ?? TokenColors.Icon.primary
            )

            let image = await avatarHandler.avatar(for: base64Handle)
            return Image(uiImage: image)
        }
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
    
    private func makeSearchResultMapper(
        with navigationController: UINavigationController
    ) -> SearchResultMapper {
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
            nodeUseCase: nodeUseCase,
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
            )
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
                repo: UserAttributeRepository.newRepo)
        )
    }

    private var nodeUseCase: some NodeUseCaseProtocol {
        NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
    }
    
    private var sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol {
        SortOrderPreferenceUseCase(
            preferenceUseCase: PreferenceUseCase.default,
            sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo
        )
    }

    private var downloadedNodesListener: some DownloadedNodesListening {
        CloudDriveDownloadedNodesListener(
            subListeners: [
                CloudDriveDownloadTransfersListener(
                    sdk: MEGASdk.sharedSdk,
                    transfersListenerUsecase: TransfersListenerUseCase(
                        repo: TransfersListenerRepository.newRepo,
                        preferenceUseCase: PreferenceUseCase.default
                    ),
                    fileSystemRepo: FileSystemRepository.sharedRepo
                ),
                NodesSavedToOfflineListener(notificationCenter: .default)
            ]
        )
    }

    private var backupsUseCase: some BackupsUseCaseProtocol {
        BackupsUseCase(
            backupsRepository: BackupsRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
    }

    private var favouriteUseCase: some NodeFavouriteActionUseCaseProtocol {
        NodeFavouriteActionUseCase(
            nodeFavouriteRepository: NodeFavouriteActionRepository.newRepo
        )
    }

    private var offlineFilesUseCase: some OfflineFilesUseCaseProtocol {
        OfflineFilesUseCase(
            repo: OfflineFileFetcherRepository.newRepo
        )
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

extension SearchResultMapper: RecentActionBucketItemResultMapping {}

private class HomeSearchViewModeStore: ViewModeStoringObjC {
    // For Home search we always display .list mode
    func viewMode(
        for location: ViewModeLocation_ObjWrapper
    ) -> ViewModePreferenceEntity {
        .list
    }
    func save(
        viewMode: ViewModePreferenceEntity,
        forObjC location: ViewModeLocation_ObjWrapper
    ) {}
}
