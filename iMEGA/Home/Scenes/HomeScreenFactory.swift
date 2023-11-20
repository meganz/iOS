import ChatRepo
import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGASDKRepo
import MEGASwift
import MEGASwiftUI
import Search
import SwiftUI

final class HomeScreenFactory: NSObject {
    
    private var sdk: MEGASdk {
        MEGASdk.sharedSdk
    }

    func createHomeScreen(
        from tabBarController: MainTabBarController,
        newHomeSearchResultsEnabled: Bool,
        tracker: some AnalyticsTracking,
        enableItemMultiSelection: Bool = false // set to true to enable multiselect [not used now in the home search results]
    ) -> UIViewController {
        let homeViewController = HomeViewController()
        let navigationController = MEGANavigationController(rootViewController: homeViewController)
        
        let myAvatarViewModel = MyAvatarViewModel(
            megaNotificationUseCase: MEGANotificationUseCase(
                userAlertsClient: .live
            ),
            megaAvatarUseCase: MEGAavatarUseCase(
                megaAvatarClient: .live,
                avatarFileSystemClient: .live,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                thumbnailRepo: ThumbnailRepository.newRepo,
                handleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
            ),
            megaAvatarGeneratingUseCase: MEGAAavatarGeneratingUseCase(
                storeUserClient: .live,
                megaAvatarClient: .live,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
            )
        )
        
        let permissionHandler: some DevicePermissionsHandling = DevicePermissionsHandler.makeHandler()
        
        let uploadViewModel = HomeUploadingViewModel(
            uploadFilesUseCase: UploadPhotoAssetsUseCase(
                uploadPhotoAssetsRepository: UploadPhotoAssetsRepository(store: MEGAStore.shareInstance())
            ),
            permissionHandler: permissionHandler,
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo),
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
                chatNodeRepository: ChatNodeRepository.newRepo
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
        
        navigationController.tabBarItem = UITabBarItem(title: nil, image: Asset.Images.TabBarIcons.home.image, selectedImage: nil)
        
        let bridge = SearchResultsBridge()
        homeViewController.searchResultsBridge = bridge
        
        let searchResultViewController = makeSearchResultViewController(
            with: navigationController,
            bridge: bridge,
            newHomeSearchResultsEnabled: newHomeSearchResultsEnabled,
            tracker: tracker,
            enableItemMultiSelection: enableItemMultiSelection
        )
        
        homeViewController.searchResultViewController = searchResultViewController
        
        let router = HomeRouter(
            navigationController: navigationController,
            tabBarController: tabBarController
        )
        homeViewController.router = router
        homeViewController.homeViewModel = HomeViewModel(
            shareUseCase: ShareUseCase(repo: ShareRepository.newRepo),
            tracker: tracker
        )
        
        return navigationController
    }
    
    private func makeNodeRepo() -> some NodeRepositoryProtocol {
        NodeRepository.newRepo
    }

    private func makeFeatureFlagProvider() -> some FeatureFlagProviderProtocol {
        DIContainer.featureFlagProvider
    }

    func makeSearchResultViewController(
        with navigationController: UINavigationController,
        bridge: SearchResultsBridge,
        newHomeSearchResultsEnabled: Bool,
        tracker: some AnalyticsTracking,
        enableItemMultiSelection: Bool
    ) -> UIViewController {
        
        if newHomeSearchResultsEnabled {
            return makeNewSearchResultsViewController(
                with: navigationController,
                bridge: bridge,
                tracker: tracker,
                enableItemMultiSelection: enableItemMultiSelection
            )
        } else {
            return makeLegacySearchResultsViewController(
                with: navigationController,
                bridge: bridge,
                tracker: tracker
            )
        }
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
    
    private func makeNewSearchResultsViewController(
        with navigationController: UINavigationController,
        bridge: SearchResultsBridge,
        tracker: some AnalyticsTracking,
        enableItemMultiSelection: Bool
    ) -> UIViewController {
        
        let router = HomeSearchResultRouter(
            navigationController: navigationController,
            nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate(
                viewController: navigationController,
                nodeActionListener: nodeActionListener(tracker)
            )
        )
        
        // this bridge is needed to do a searchBar <-> searchResults -> homeScreen communication without coupling this to
        // MEGA app level delegates. Using simple closures to pass data back and forth
        let searchBridge = SearchBridge(
            selection: { [weak sdk] result in
                router.didTapNode(result.id)
                // map from result id to a node to check if this is folder or a file
                if let node = sdk?.node(forHandle: result.id) {
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
                router.didTapMoreAction(on: result.id, button: button)
            },
            resignKeyboard: { [weak bridge] in
                bridge?.hideKeyboard()
            },
            chipTapped: { chip, selected in
                tracker.trackChip(tapped: chip, selected: selected)
            }
        )
        
        bridge.didInputTextTrampoline = { [weak searchBridge] text in
            searchBridge?.queryChanged(text)
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
            resultsProvider: HomeSearchResultsProvider(
                searchFileUseCase: makeSearchFileUseCase(),
                nodeDetailUseCase: makeNodeDetailUseCase(),
                nodeUseCase: makeNodeUseCase(),
                mediaUseCase: makeMediaUseCase(),
                nodeRepository: makeNodeRepo(),
                featureFlagProvider: makeFeatureFlagProvider(),
                sdk: sdk
            ),
            bridge: searchBridge,
            config: .searchConfig(
                contextPreviewFactory: contextPreviewFactory(
                enableItemMultiSelection: enableItemMultiSelection
                )
            ),
            isThumbnailPreviewEnabled: DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .thumbnailSearchPreview),
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default)
        )
        return UIHostingController(rootView: SearchResultsView(viewModel: vm))
    }
    
    func previewViewController(for node: MEGANode) -> UIViewController? {
        if node.isFolder() {
            let storyboard = UIStoryboard(name: "Cloud", bundle: nil)
            let cloudDriveVC = storyboard.instantiateViewController(identifier: "CloudDriveID") as! CloudDriveViewController
            
            cloudDriveVC.parentNode = node
            
            return cloudDriveVC
        } else {
            return nil
        }
    }
    
    private func contextPreviewFactory(enableItemMultiSelection: Bool) -> SearchConfig.ContextPreviewFactory {
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
            // action (selection) will be implemented in [FM-1176]
            .init(
                title: Strings.Localizable.select,
                imageName: "checkmark.circle",
                handler: {
                    print("selected tapped")
                })
        ]
    }
    
    private func makeNodeDetailUseCase() -> some NodeDetailUseCaseProtocol {
        NodeDetailUseCase(
            sdkNodeClient: .live,
            nodeThumbnailHomeUseCase: NodeThumbnailHomeUseCase(
                sdkNodeClient: .live,
                fileSystemClient: .live,
                thumbnailRepo: ThumbnailRepository.newRepo
            )
        )
    }
    
    private func makeSearchFileUseCase() -> some SearchFileUseCaseProtocol {
        SearchFileUseCase(
            nodeSearchClient: .live,
            searchFileHistoryUseCase: SearchFileHistoryUseCase(
                fileSearchHistoryRepository: .live
            )
        )
    }

    private func makeNodeUseCase() -> some NodeUseCaseProtocol {
        NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
    }

    private func makeMediaUseCase() -> some MediaUseCaseProtocol {
        MediaUseCase(
            fileSearchRepo: FilesSearchRepository.newRepo,
            videoMediaUseCase: VideoMediaUseCase(videoMediaRepository: VideoMediaRepository.newRepo)
        )
    }

    private func makeLegacySearchResultsViewController(
        with navigationController: UINavigationController,
        bridge: SearchResultsBridge,
        tracker: some AnalyticsTracking
    ) -> UIViewController {
        let searchResultViewModel = HomeSearchResultViewModel(
            searchFileUseCase: makeSearchFileUseCase(),
            searchFileHistoryUseCase: SearchFileHistoryUseCase(
                fileSearchHistoryRepository: .live
            ),
            nodeDetailUseCase: makeNodeDetailUseCase(),
            router: HomeSearchResultRouter(
                navigationController: navigationController,
                nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate(
                    viewController: navigationController,
                    nodeActionListener: nodeActionListener(tracker)
                )
            ),
            tracker: tracker,
            sdk: sdk
        )
        
        let homeSearchResultViewController = HomeSearchResultViewController()
        homeSearchResultViewController.viewModel = searchResultViewModel
        homeSearchResultViewController.resultTableViewDataSource
        = TableViewProxy<HomeSearchResultFileViewModel>(
            cellIdentifier: "SearchResultFile",
            emptyStateConfiguration: .searchResult,
            configureCell: { cell, model in
                (cell as? SearchResultFileTableViewCell)?.configure(with: model)
            },
            selectionAction: { selectedNode in
                searchResultViewModel.didSelectNode(selectedNode.handle)
            }
        )
        
        homeSearchResultViewController.hintTableViewDataSource = TableViewProxy<HomeSearchHintViewModel>(
            cellIdentifier: "SearchHint",
            emptyStateConfiguration: .searchHints,
            configureCell: { cell, model in
                (cell as? SearchHintTableViewCell)?.configure(with: model)
            },
            selectionAction: { selectedSearchHint in
                searchResultViewModel.didSelectHint(selectedSearchHint.text)
            }
        )
        // setting up the bridge connection instead of just connecting delegates
        homeSearchResultViewController.searchHintSelectDelegate = bridge
        
        bridge.didClearTrampoline = { [weak homeSearchResultViewController] in
            homeSearchResultViewController?.didClearText()
        }
        
        bridge.didInputTextTrampoline = { [weak homeSearchResultViewController] text in
            homeSearchResultViewController?.didInputText(text)
        }
        
        bridge.didHighlightTrampoline = { [weak homeSearchResultViewController] in
            homeSearchResultViewController?.didHighlightSearchBar()
        }
        
        return homeSearchResultViewController
    }
}
