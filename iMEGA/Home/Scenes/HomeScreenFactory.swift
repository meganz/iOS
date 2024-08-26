import ChatRepo
import Foundation
import MEGAAnalyticsiOS
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGARepo
import MEGASDKRepo
import MEGASwift
import MEGASwiftUI
import MEGAUIKit
import Search
import SwiftUI

final class HomeScreenFactory: NSObject {
    
    private var sdk: MEGASdk {
        MEGASdk.sharedSdk
    }
    
    private var megaStore: MEGAStore {
        MEGAStore.shareInstance()
    }
    
    // shared with ObjC code so need Objc version
    private var newViewModeStore: some ViewModeStoringObjC {
        ViewModeStore(
            preferenceRepo: PreferenceRepository(userDefaults: .standard),
            megaStore: megaStore,
            sdk: sdk,
            notificationCenter: notificationCenter
        )
    }

    func createHomeScreen(
        from tabBarController: MainTabBarController,
        tracker: some AnalyticsTracking,
        enableItemMultiSelection: Bool = false // set to true to enable multi-select [not used now in the home search results]
    ) -> UIViewController {
        let homeViewController = HomeViewController()
        let navigationController = MEGANavigationController(
            rootViewController: homeViewController
        )
        
        let myAvatarViewModel = MyAvatarViewModel(
            megaNotificationUseCase: MEGANotificationUseCase(
                userAlertsClient: .live,
                notificationsUseCase: NotificationsUseCase(repository: NotificationsRepository.newRepo)
            ), userImageUseCase: UserImageUseCase(
                userImageRepo: UserImageRepository.newRepo,
                userStoreRepo: UserStoreRepository.newRepo,
                thumbnailRepo: ThumbnailRepository.newRepo,
                fileSystemRepo: FileSystemRepository.newRepo
            ), megaHandleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
        )
        
        let permissionHandler: some DevicePermissionsHandling = DevicePermissionsHandler.makeHandler()
        
        let uploadViewModel = HomeUploadingViewModel(
            uploadFilesUseCase: UploadPhotoAssetsUseCase(
                uploadPhotoAssetsRepository: UploadPhotoAssetsRepository(store: megaStore)
            ),
            permissionHandler: permissionHandler,
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo),
            tracker: tracker,
            router: FileUploadingRouter(navigationController: navigationController, baseViewController: homeViewController)
        )
        
        homeViewController.myAvatarViewModel = myAvatarViewModel
        homeViewController.uploadViewModel = uploadViewModel
        homeViewController.startConversationViewModel = StartConversationViewModel(
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            router: NewChatRouter(
                navigationController: navigationController,
                tabBarController: tabBarController
            )
        )
        homeViewController.recentsViewModel = HomeRecentActionViewModel(
            permissionHandler: permissionHandler,
            nodeFavouriteActionUseCase: NodeFavouriteActionUseCase(
                nodeFavouriteRepository: NodeFavouriteActionRepository.newRepo
            ),
            saveMediaToPhotosUseCase: SaveMediaToPhotosUseCase(
                downloadFileRepository: DownloadFileRepository(sdk: sdk),
                fileCacheRepository: FileCacheRepository.newRepo,
                nodeRepository: makeNodeRepo(),
                chatNodeRepository: ChatNodeRepository.newRepo,
                downloadChatRepository: DownloadChatRepository.newRepo
            )
        )
        homeViewController.bannerViewModel = HomeBannerViewModel(
            userBannerUseCase: UserBannerUseCase(
                userBannerRepository: BannerRepository.newRepo
            ),
            router: HomeBannerRouter(navigationController: navigationController)
        )
        
        homeViewController.quickAccessWidgetViewModel = QuickAccessWidgetViewModel(
            offlineFilesUseCase: OfflineFilesUseCase(
                repo: OfflineFileFetcherRepository.newRepo
            )
        )
        
        navigationController.tabBarItem = UITabBarItem(title: nil, image: UIImage.home, selectedImage: nil)
        
        let viewModeStore = newViewModeStore
        homeViewController.viewModeStore = viewModeStore
        
        let bridge = SearchResultsBridge()
        homeViewController.searchResultsBridge = bridge
        
        let searchResultViewController = makeSearchResultViewController(
            with: navigationController,
            bridge: bridge,
            tracker: tracker,
            viewModeStore: viewModeStore,
            enableItemMultiSelection: enableItemMultiSelection
        )
        
        homeViewController.searchResultViewController = searchResultViewController
        
        let router = HomeRouter(
            navigationController: navigationController,
            tabBarController: tabBarController
        )
        homeViewController.router = router
        homeViewController.homeViewModel = HomeViewModel(
            shareUseCase: ShareUseCase(
                shareRepository: ShareRepository.newRepo,
                filesSearchRepository: FilesSearchRepository.newRepo,
                nodeRepository: NodeRepository.newRepo),
            tracker: tracker
        )
        
        return navigationController
    }
    
    private func makeNodeRepo() -> some NodeRepositoryProtocol {
        NodeRepository.newRepo
    }
    
    private func makeNodeIconUsecase() -> some NodeIconUsecaseProtocol {
        NodeIconUseCase(nodeIconRepo: NodeAssetsManager.shared)
    }

    private func makeFeatureFlagProvider() -> some FeatureFlagProviderProtocol {
        DIContainer.featureFlagProvider
    }
    
    private func makeNodesUpdateListenerRepo() -> some NodesUpdateListenerProtocol {
        SDKNodesUpdateListenerRepository(sdk: sdk)
    }

    private func makeDownloadTransfersListener() -> some DownloadTransfersListening {
        CloudDriveDownloadTransfersListener(sdk: sdk, transfersListenerUsecase: TransfersListenerUseCase(repo: TransfersListenerRepository.newRepo), fileSystemRepo: FileSystemRepository.newRepo)
    }

    func makeSearchResultViewController(
        with navigationController: UINavigationController,
        bridge: SearchResultsBridge,
        tracker: some AnalyticsTracking,
        viewModeStore: some ViewModeStoringObjC,
        enableItemMultiSelection: Bool
    ) -> UIViewController {
        
        let router = HomeSearchResultRouter(
            navigationController: navigationController,
            nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate(
                viewController: navigationController,
                moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: navigationController),
                nodeActionListener: nodeActionListener(tracker)
            ),
            backupsUseCase: makeBackupsUseCase(),
            nodeUseCase: makeNodeUseCase()
        )
        
        // this bridge is needed to do a searchBar <-> searchResults -> homeScreen communication without coupling this to
        // MEGA app level delegates. Using simple closures to pass data back and forth
        let searchBridge = SearchBridge(
            selection: { [weak sdk] selection in
                let resultId = selection.result.id
                // currently, home search results (legacy and new) page does not support
                // image gallery browsing, to enable this , allNodes need to be supplied to router
                // see CloudDriveViewControllerFactory.swift for an example
                router.didTapNode(nodeHandle: resultId)
                // map from result id to a node to check if this is folder or a file
                if let node = sdk?.node(forHandle: resultId) {
                    let event = SearchItemSelectedEvent(
                        searchItemType: node.isFolder() ? .folder : .file
                    )
                    tracker.trackAnalyticsEvent(with: event)
                }
            },
            context: { result, button in
                let event = SearchResultOverflowMenuItemEvent()
                tracker.trackAnalyticsEvent(with: event)
                
                // button reference is required to position popover on the iPad correctly
                router.didTapMoreAction(on: result.id, button: button, isFromSharedItem: false)
            },
            resignKeyboard: { [weak bridge] in
                bridge?.hideKeyboard()
            },
            chipTapped: { chip, selected in
                tracker.trackChip(tapped: chip, selected: selected)
            }, sortingOrder: {
                .nameAscending
            }
        )
        
        bridge.didInputTextTrampoline = { [weak searchBridge] text in
            searchBridge?.queryChanged(text)
        }
        
        bridge.didChangeLayoutTrampoline = {[weak searchBridge] layout in
            searchBridge?.layoutChanged(layout)
        }
        
        bridge.didClearTrampoline = { [weak searchBridge] in
            searchBridge?.queryCleaned()
        }
        
        bridge.didFinishSearchingTrampoline = { [weak searchBridge] in
            searchBridge?.searchCancelled()
        }
        
        bridge.updateBottomInsetTrampoline = { [weak searchBridge] inset in
            searchBridge?.updateBottomInset(inset)
        }
        
        let vm = SearchResultsViewModel(
            resultsProvider: makeResultsProvider(
                parentNodeProvider: {[weak sdk] in sdk?.rootNode?.toNodeEntity() },
                searchBridge: searchBridge,
                navigationController: navigationController
            ),
            bridge: searchBridge,
            config: .searchConfig(
                contextPreviewFactory: contextPreviewFactory(
                    enableItemMultiSelection: enableItemMultiSelection
                ),
                defaultEmptyViewAsset: {
                    .init(
                        image: Image(.searchEmptyState),
                        title: Strings.Localizable.Home.Search.Empty.noChipSelected,
                        titleTextColor: { colorScheme in
                            guard DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) else {
                                return colorScheme == .light ? UIColor.gray515151.swiftUI : UIColor.grayD1D1D1.swiftUI
                            }
                            
                            return TokenColors.Icon.secondary.swiftUI
                        }
                    )
                }
            ),
            layout: viewModeStore.viewMode(for: .init(customLocation: CustomViewModeLocation.HomeSearch)).pageLayout ?? .list,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: notificationCenter),
            viewDisplayMode: .home
        )
        return UIHostingController(
            rootView: SearchResultsView(viewModel: vm)
                .designTokenBackground(true)
        )
    }
    
    private func nodeActionListener(_ tracker: any AnalyticsTracking) -> (MegaNodeActionType?) -> Void {
        { action in
            switch action {
            case .saveToPhotos:
                tracker.trackAnalyticsEvent(with: SearchResultSaveToDeviceMenuItemEvent())
            case .manageLink, .shareLink:
                tracker.trackAnalyticsEvent(with: SearchResultShareMenuItemEvent())
            default:
                {}() // we do not track other events here yet
            }
        }
    }
    
    func makeRouter(
        navController: UINavigationController,
        tracker: some AnalyticsTracking
    ) -> some NodeRouting {
        HomeSearchResultRouter(
            navigationController: navController,
            nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate(
                viewController: navController,
                moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: navController),
                nodeActionListener: nodeActionListener(tracker)
            ),
            backupsUseCase: makeBackupsUseCase(),
            nodeUseCase: makeNodeUseCase()
        )
    }
    
    func makeBackupsUseCase() -> some BackupsUseCaseProtocol {
         BackupsUseCase(
            backupsRepository: BackupsRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
         )
    }

    func makeResultsProvider(
        parentNodeProvider: @escaping () -> NodeEntity?,
        searchBridge: SearchBridge,
        navigationController: UINavigationController
    ) -> HomeSearchResultsProvider {
        let featureFlagProvider = makeFeatureFlagProvider()
        return HomeSearchResultsProvider(
            parentNodeProvider: parentNodeProvider,
            filesSearchUseCase: makeFilesSearchUseCase(),
            nodeDetailUseCase: makeNodeDetailUseCase(),
            nodeUseCase: makeNodeUseCase(),
            mediaUseCase: makeMediaUseCase(),
            nodesUpdateListenerRepo: makeNodesUpdateListenerRepo(),
            downloadTransferListener: makeDownloadTransfersListener(),
            nodeIconUsecase: makeNodeIconUsecase(),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
            allChips: Self.allChips(),
            sdk: sdk,
            nodeActions: .makeActions(sdk: sdk, navigationController: navigationController),
            hiddenNodesFeatureEnabled: featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
            isDesignTokenEnabled: featureFlagProvider.isFeatureFlagEnabled(for: .designToken),
            onSearchResultsUpdated: { [weak searchBridge] searchResult in
                searchBridge?.onSearchResultsUpdated(searchResult)
            }
        )
    }
    private static func allChips() -> [SearchChipEntity] {
        SearchChipEntity.allChips(
            currentDate: { .init() },
            calendar: .autoupdatingCurrent
        )
    }
    
    var notificationCenter: NotificationCenter {
        .default
    }
    
    func previewViewController(
        for node: MEGANode
    ) -> UIViewController? {
        if node.isFolder() {
            let factory = CloudDriveViewControllerFactory.make()
            // For preview mode, we don't support upgrade encouragement flow
            let config = NodeBrowserConfig.withSupportsUpgradeEncouragement(false)
            return factory.buildBare(parentNode: node.toNodeEntity(), config: config)
        } else {
            return nil
        }
    }
    
    func contextPreviewFactory(enableItemMultiSelection: Bool) -> SearchConfig.ContextPreviewFactory {
        .init(
            // this logic below, constructs actions and preview
            // when an search item is long pressed
            previewContentForResult: { [weak sdk] result in
                guard let sdk else {
                    return .init(actions: [], previewMode: .noPreview)
                }
                
                if let node = sdk.node(forHandle: result.id) {
                    let previewMode: () -> PreviewContent.PreviewMode = {
                        if node.type == .folder {
                            return .preview {
                                self.previewViewController(for: node)
                            }
                        } else {
                            return .noPreview
                        }
                    }
                    return .init(
                        actions: self.actionsFor(node: node, enableItemMultiSelection: enableItemMultiSelection),
                        previewMode: previewMode()
                    )
                }
                return .init(actions: [], previewMode: .noPreview)
            }
        )
    }
    
    private func actionsFor(node: MEGANode, enableItemMultiSelection: Bool) -> [PeekAction] {
        guard enableItemMultiSelection else {
            // if not enabled, there's no preview action returned
            return []
        }
        return [
            .init(
                title: Strings.Localizable.select,
                imageName: "checkmark.circle",
                handler: {
                    print("selected tapped")
                })
        ]
    }
    
    func makeNodeDetailUseCase() -> some NodeDetailUseCaseProtocol {
        NodeDetailUseCase(
            sdkNodeClient: .live,
            nodeThumbnailHomeUseCase: NodeThumbnailHomeUseCase(
                sdkNodeClient: .live,
                fileSystemClient: .live,
                thumbnailRepo: ThumbnailRepository.newRepo
            )
        )
    }
    
    private func makeFilesSearchUseCase() -> some FilesSearchUseCaseProtocol {
        FilesSearchUseCase(
            repo: FilesSearchRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
    }

    func makeNodeUseCase() -> some NodeUseCaseProtocol {
        NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
    }

    func makeMediaUseCase() -> some MediaUseCaseProtocol {
        MediaUseCase(
            fileSearchRepo: FilesSearchRepository.newRepo,
            videoMediaUseCase: VideoMediaUseCase(videoMediaRepository: VideoMediaRepository.newRepo)
        )
    }
}
