import Foundation  
import MEGADomain
import MEGAPermissions
import MEGASDKRepo
import Search
import SwiftUI

final class HomeScreenFactory: NSObject {
    
    private var sdk: MEGASdk {
        MEGASdk.sharedSdk
    }

    func createHomeScreen(
        from tabBarController: MainTabBarController,
        newHomeSearchResultsEnabled: Bool
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
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository()),
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo),
            router: FileUploadingRouter(navigationController: navigationController, baseViewController: homeViewController)
        )

        homeViewController.myAvatarViewModel = myAvatarViewModel
        homeViewController.uploadViewModel = uploadViewModel
        homeViewController.startConversationViewModel = StartConversationViewModel(
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository()),
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
                nodeRepository: NodeRepository.newRepo
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
            newHomeSearchResultsEnabled: newHomeSearchResultsEnabled
        )
        
        homeViewController.searchResultViewController = searchResultViewController

        let router = HomeRouter(
            navigationController: navigationController,
            tabBarController: tabBarController
        )
        homeViewController.router = router
        homeViewController.homeViewModel = HomeViewModel(
            shareUseCase: ShareUseCase(repo: ShareRepository.newRepo)
        )

        return navigationController
    }

    private func makeSearchResultViewController(
        with navigationController: UINavigationController,
        bridge: SearchResultsBridge,
        newHomeSearchResultsEnabled: Bool
    ) -> UIViewController {

        if newHomeSearchResultsEnabled {
            return makeNewSearchResultsViewController(
                with: navigationController,
                bridge: bridge
            )
        } else {
            return makeLegacySearchResultsViewController(
                with: navigationController,
                bridge: bridge
            )
        }
    }
    
    private func makeNewSearchResultsViewController(
        with navigationController: UINavigationController,
        bridge: SearchResultsBridge
    ) -> UIViewController {
        
        let router = HomeSearchResultRouter(
            navigationController: navigationController,
            nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate(
                viewController: navigationController
            )
        )
        
        // put some real value here to make it work
        // this is put here until we have real API calls and real data
        let fakeNode: HandleEntity = 221064586114322
        
        // this bridge is needed to do a searchBar <-> searchResults -> homeScreen communication without coupling this to
        // MEGA app level delegates. Using simple closures to pass data back and forth
        let searchBridge = SearchBridge(
            selection: { _ in
                router.didTapNode(fakeNode)
            },
            context: { _ in
                // will try to remove the dummy button required by the API on later MR's
                router.didTapMoreAction(on: fakeNode, button: UIButton())
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
        
        let vm = SearchResultsViewModel(
            resultsProvider: NonProductionTestResultsProvider(),
            bridge: searchBridge
        )
        return UIHostingController(rootView: SearchResultsView(viewModel: vm))
    }
    
    private func makeLegacySearchResultsViewController(
        with navigationController: UINavigationController,
        bridge: SearchResultsBridge
    ) -> UIViewController {
        let searchResultViewModel = HomeSearchResultViewModel(
            searchFileUseCase: SearchFileUseCase(
                nodeSearchClient: .live,
                searchFileHistoryUseCase: SearchFileHistoryUseCase(
                    fileSearchHistoryRepository: .live
                )
            ),
            searchFileHistoryUseCase: SearchFileHistoryUseCase(
                fileSearchHistoryRepository: .live
            ),
            nodeDetailUseCase: NodeDetailUseCase(
                sdkNodeClient: .live,
                nodeThumbnailHomeUseCase: NodeThumbnailHomeUseCase(
                    sdkNodeClient: .live,
                    fileSystemClient: .live,
                    thumbnailRepo: ThumbnailRepository.newRepo
                )
            ),
            router: HomeSearchResultRouter(
                navigationController: navigationController,
                nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate(
                    viewController: navigationController
                )
            )
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
