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

        let router = HomeViewRouter(navigationController: navigationController)
        let dependency = HomeView.Dependency(
            homeAddMenuActionHandler: makeHomeAddMenuActionHandler(newChatRouter: newChatRouter, navigationController: navigationController),
            router: router,
            fullNameHandler: fullNameHandler,
            userImageUseCase: userImageUseCase,
            avatarFetcher: makeAvatarFetcher(
                fullNameHandler: fullNameHandler,
                userImageUseCase: userImageUseCase,
                megaHandleUseCase: megaHandleUseCase
            ),
            fileSearchUseCase: fileSearchUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            favouritesSearchResultsMapper: makeFavouritesSearchResultsMapper(with: navigationController),
            downloadedNodesListener: downloadedNodesListener,
            nodeUseCase: nodeUseCase,
            favouritesContextAction: makeFavouritesContextAction(navigationController: navigationController),
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase
        )
        
        let homeView = HomeView(dependency: dependency)

        let hostingController = HomeViewHostingController(rootView: homeView)

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

    private func makeFavouritesContextAction(
        navigationController: UINavigationController
    ) -> @MainActor (HandleEntity, UIButton) -> Void {
        { [weak navigationController] handle, button in
            guard let navigationController else { return }
            let backupsUseCase = BackupsUseCase(
                backupsRepository: BackupsRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            )
            let isBackupNode = backupsUseCase.isBackupNodeHandle(handle)
            let delegate = NodeActionViewControllerGenericDelegate(
                viewController: navigationController,
                moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: navigationController)
            )
            guard let nodeActionViewController = NodeActionViewController(
                node: handle,
                delegate: delegate,
                displayMode: .cloudDrive,
                isIncoming: false,
                isBackupNode: isBackupNode,
                isFromSharedItem: false,
                sender: button
            ) else {
                return
            }
            navigationController.present(nodeActionViewController, animated: true)
        }
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
