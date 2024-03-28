import Foundation
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGARepo
import MEGASDKRepo
import MEGASwift
import Search
import SwiftUI
import UIKit

struct CloudDriveViewControllerFactory {
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let abTestProvider: any ABTestProviderProtocol
    private let navigationController: UINavigationController
    private let viewModeStore: any ViewModeStoring
    private let router: any NodeRouting
    private let tracker: any AnalyticsTracking
    private let mediaAnalyticsUseCase: any MediaDiscoveryAnalyticsUseCaseProtocol
    private let mediaDiscoveryUseCase: any MediaDiscoveryUseCaseProtocol
    private let homeScreenFactory: HomeScreenFactory
    private let nodeUseCase: any NodeUseCaseProtocol
    private let preferences: any PreferenceUseCaseProtocol
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let resultsMapper: SearchResultMapper
    private let sdk: MEGASdk
    private let userDefaults: UserDefaults
    private let contextMenuConfigFactory: CloudDriveContextMenuConfigFactory
    private let backupsUseCase: any BackupsUseCaseProtocol
    private let avatarViewModel: MyAvatarViewModel
    private let rubbishBinUseCase: any RubbishBinUseCaseProtocol
    private let createContextMenuUseCase: any CreateContextMenuUseCaseProtocol
    private let nodeActions: NodeActions
    private let viewModeFactory: InitialViewModeFactory
    
    init(
        featureFlagProvider: some FeatureFlagProviderProtocol,
        abTestProvider: some ABTestProviderProtocol,
        navigationController: UINavigationController,
        viewModeStore: some ViewModeStoring,
        router: some NodeRouting,
        tracker: some AnalyticsTracking,
        mediaAnalyticsUseCase: some MediaDiscoveryAnalyticsUseCaseProtocol,
        mediaDiscoveryUseCase: some MediaDiscoveryUseCaseProtocol,
        homeScreenFactory: HomeScreenFactory,
        resultsMapper: SearchResultMapper,
        nodeUseCase: some NodeUseCaseProtocol,
        preferences: some PreferenceUseCaseProtocol,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        sdk: MEGASdk,
        userDefaults: UserDefaults,
        contextMenuConfigFactory: CloudDriveContextMenuConfigFactory,
        backupsUseCase: some BackupsUseCaseProtocol,
        rubbishBinUseCase: some RubbishBinUseCaseProtocol,
        createContextMenuUseCase: some CreateContextMenuUseCaseProtocol,
        nodeActions: NodeActions
    ) {
        self.featureFlagProvider = featureFlagProvider
        self.abTestProvider = abTestProvider
        self.navigationController = navigationController
        self.viewModeStore = viewModeStore
        self.router = router
        self.tracker = tracker
        self.mediaAnalyticsUseCase = mediaAnalyticsUseCase
        self.mediaDiscoveryUseCase = mediaDiscoveryUseCase
        self.homeScreenFactory = homeScreenFactory
        self.resultsMapper = resultsMapper
        self.nodeUseCase = nodeUseCase
        self.preferences = preferences
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.sdk = sdk
        self.userDefaults = userDefaults
        self.contextMenuConfigFactory = contextMenuConfigFactory
        self.backupsUseCase = backupsUseCase
        self.rubbishBinUseCase = rubbishBinUseCase
        self.createContextMenuUseCase = createContextMenuUseCase
        self.nodeActions = nodeActions
        
        self.avatarViewModel = MyAvatarViewModel(
            megaNotificationUseCase: MEGANotificationUseCase(
                userAlertsClient: .live,
                notificationsUseCase: NotificationsUseCase(repository: NotificationsRepository.newRepo)
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
        
        self.avatarViewModel.inputs.viewIsReady()
        
        viewModeFactory = InitialViewModeFactory(viewModeStore: viewModeStore)
    }
    
    static func make(nc: UINavigationController? = nil) -> CloudDriveViewControllerFactory {
        let sdk = MEGASdk.shared
        let homeFactory = HomeScreenFactory()
        let tracker = DIContainer.tracker
        
        let navController = nc ?? MEGANavigationController(rootViewController: UIViewController())
        
        let router = homeFactory.makeRouter(
            navController: navController,
            tracker: tracker
        )
        
        let nodeUseCase = homeFactory.makeNodeUseCase()
        let backupsUseCase = BackupsUseCase(
            backupsRepository: BackupsRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
        
        let nodeAssetsManager = NodeAssetsManager.shared
        
        return CloudDriveViewControllerFactory(
            featureFlagProvider: DIContainer.featureFlagProvider,
            abTestProvider: DIContainer.abTestProvider,
            navigationController: navController,
            viewModeStore: ViewModeStore(
                preferenceRepo: PreferenceRepository(userDefaults: UserDefaults.standard),
                megaStore: .shareInstance(),
                sdk: sdk,
                notificationCenter: .default
            ),
            router: router,
            tracker: tracker,
            mediaAnalyticsUseCase: MediaDiscoveryAnalyticsUseCase(
                repository: AnalyticsRepository.newRepo
            ),
            mediaDiscoveryUseCase: MediaDiscoveryUseCase(
                filesSearchRepository: FilesSearchRepository(sdk: sdk),
                nodeUpdateRepository: NodeUpdateRepository(sdk: sdk)
            ),
            homeScreenFactory: homeFactory,
            resultsMapper: SearchResultMapper(
                sdk: sdk,
                nodeIconUsecase: NodeIconUseCase(nodeIconRepo: nodeAssetsManager),
                nodeDetailUseCase: homeFactory.makeNodeDetailUseCase(),
                nodeUseCase: nodeUseCase,
                mediaUseCase: homeFactory.makeMediaUseCase()
            ),
            nodeUseCase: nodeUseCase,
            preferences: PreferenceUseCase.default, 
            sortOrderPreferenceUseCase: SortOrderPreferenceUseCase(
                preferenceUseCase: PreferenceUseCase.default,
                sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo
            ),
            sdk: sdk,
            userDefaults: .standard,
            contextMenuConfigFactory: CloudDriveContextMenuConfigFactory(
                backupsUseCase: backupsUseCase,
                nodeUseCase: nodeUseCase
            ),
            backupsUseCase: backupsUseCase,
            rubbishBinUseCase: DIContainer.rubbishBinUseCase,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo),
            nodeActions: .makeActions(
                sdk: sdk,
                navigationController: navController
            )
        )
    }
    
    private func useNewCloudDrive(config: NodeBrowserConfig) -> Bool {
        let featureEnabled = userDefaults.bool(forKey: Helper.cloudDriveABTestCacheKey()) ||
        featureFlagProvider.isFeatureFlagEnabled(for: .newCloudDrive)
        // disable new Cloud Drive for recents as it's very different
        // config with sections, the ticket to implement the needed behaviour: [FM-1691]
        return featureEnabled && config.displayMode != .recents
    }
    
    /// build bare is return a plain UIViewController, bare-less version returns one wrapped in the UINavigationController
    func buildBare(
        parentNode: NodeEntity,
        config: NodeBrowserConfig = .default
    ) -> UIViewController? {
        buildBare(nodeSource: .node({ parentNode }), config: config)
    }
    
    func build(
        rootNodeProvider: @escaping ParentNodeProvider,
        config: NodeBrowserConfig
    ) -> UIViewController? {
        build(nodeSource: .node(rootNodeProvider), config: config)
    }
    
    func build(
        parentNode: NodeEntity,
        config: NodeBrowserConfig
    ) -> UIViewController? {
        build(nodeSource: .node({ parentNode }), config: config)
    }
    
    func buildBare(
        nodeSource: NodeSource,
        config: NodeBrowserConfig
    ) -> UIViewController? {
        if useNewCloudDrive(config: config) {
            newCloudDriveViewController(
                nodeSource: nodeSource,
                config: config
            )
        } else {
            LegacyCloudDriveViewControllerFactory().build(
                nodeSource: nodeSource,
                config: config,
                sdk: sdk
            )
        }
    }
    
    func build(
        nodeSource: NodeSource,
        config: NodeBrowserConfig
    ) -> UIViewController? {
        guard
            let vc = buildBare(nodeSource: nodeSource, config: config)
        else { return navigationController }
        
        navigationController.viewControllers = [vc]
        navigationController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage.cloudDriveIcon,
            selectedImage: nil
        )
        
        if
            let legacy = vc as? (any MyAvatarPresenterProtocol),
            config.showsAvatar == true {
            legacy.configureMyAvatarManager()
        }
        
        return navigationController
    }
    
    private func makeNodeBrowserViewModel(
        initialViewMode: ViewModePreferenceEntity,
        sortOrder: MEGADomain.SortOrderEntity,
        nodeSource: NodeSource,
        searchResultsViewModel: SearchResultsViewModel,
        config: NodeBrowserConfig,
        nodeActions: NodeActions,
        navigationController: UINavigationController,
        mediaContentDelegate: MediaContentDelegateHandler,
        searchControllerWrapper: SearchControllerWrapper,
        onSelectionModeChange: @escaping (Bool) -> Void
    ) -> NodeBrowserViewModel {
        
        let upgradeEncouragementViewModel: UpgradeEncouragementViewModel? = config.supportsUpgradeEncouragement ? .init() : nil
        let adsVisibilityViewModel = AdsVisibilityViewModel(configuratorProvider: config.adsConfiguratorProvider)
        
        return .init(
            viewMode: initialViewMode,
            searchResultsViewModel: searchResultsViewModel,
            mediaDiscoveryViewModel: makeOptionalMediaDiscoveryViewModel(
                nodeSource: nodeSource,
                mediaContentDelegate: mediaContentDelegate,
                isShowingAutomatically: initialViewMode == .mediaDiscovery
            ),
            warningViewModel: makeOptionalWarningViewModel(
                nodeSource,
                config: config
            ),
            upgradeEncouragementViewModel: upgradeEncouragementViewModel,
            adsVisibilityViewModel: adsVisibilityViewModel,
            config: config,
            nodeSource: nodeSource,
            sortOrder: sortOrder,
            avatarViewModel: avatarViewModel,
            viewModeSaver: {
                guard let node = nodeSource.parentNode else { return }
                viewModeStore.save(viewMode: $0, for: .node(node))
            },
            storageFullAlertViewModel: StorageFullAlertViewModel(router: StorageFullModalAlertViewController(nibName: nil, bundle: nil)),
            titleBuilder: { isEditing, selectedNodesCount in
                // The code below is needed due the fact that most of new code uses NodeEntity struct
                // and for the code to be robust and reuse the title logic, title should be derived from
                // from the actual node for normal and renaming scenarios.
                // For this reason, instead of passing the immutable NodeEntity struct, we
                // are supplying a closure that caches the node handle
                // and accesses actual node from the SDK data base whenever need, guaranteeing
                // consistency between screen title and SDK state
                let persistentNodeSourceProvider: () -> NodeSource = {
                    switch nodeSource {
                    case .node(let provider):
                        guard let nodeHandle = provider()?.handle else { return nodeSource }
                        return .node({
                            nodeUseCase.nodeForHandle(nodeHandle)
                        })
                    case .recentActionBucket:
                        return nodeSource
                    }
                }
                return titleFor(
                    persistentNodeSourceProvider(),
                    config: config,
                    isEditModeActive: isEditing,
                    selectedNodesArrayCount: selectedNodesCount
                ) ?? ""
            },
            onOpenUserProfile: { nodeActions.userProfileOpener(navigationController) },
            onUpdateSearchBarVisibility: { searchControllerWrapper.onUpdateSearchBarVisibility?($0) },
            onBack: { self.navigationController.popViewController(animated: true) },
            onEditingChanged: { enabled in
                onSelectionModeChange(enabled)
            }
        )
    }
    
    // This factory method creates all the machinery need to show and handle three dot context menu
    // ContextMenuManager holds weak references to the action handles, so they
    // need to be retained in the viewModel to make sure they live as long as the view
    private func makeContextMenuManager(
        nodeSource: NodeSource,
        nodeBrowserViewModel: NodeBrowserViewModel,
        navigationController: UINavigationController
    ) -> (ContextMenuManager, [AnyObject]) {
        
        // All node actions triggered via context menus (three dot or toolbar)
        // are handled from a central place: NodeActions which keeps
        // closure that can execute each operation
        // possible improvement is to also use this mechanism
        // when three dots are tapped on the single node cell
        
        let displayMenuDelegateHandler = DisplayMenuDelegateHandler(
            rubbishBinUseCase: rubbishBinUseCase,
            toggleSelection: { [weak nodeBrowserViewModel] in
                nodeBrowserViewModel?.toggleSelection()
            },
            changeViewMode: { [weak nodeBrowserViewModel] in
                nodeBrowserViewModel?.changeViewMode($0)
            }, changeSortOrder: { [weak nodeBrowserViewModel] sortOrder in
                if let parentNode = nodeSource.parentNode {
                    sortOrderPreferenceUseCase.save(sortOrder: sortOrder.toSortOrderEntity(), for: parentNode)
                }

                nodeBrowserViewModel?.changeSortOrder(sortOrder)
            }
        )
        
        displayMenuDelegateHandler.presenterViewController = navigationController
        
        let quickActionsMenuDelegateHandler = QuickActionsMenuDelegateHandler(
            showNodeInfo: nodeActions.showNodeInfo,
            manageShare: { nodeActions.manageShare([$0]) },
            shareFolders: nodeActions.shareFolders,
            download: nodeActions.nodeDownloader,
            shareOrManageLink: nodeActions.shareOrManageLink,
            copy: { nodeActions.browserAction(.copy, [$0]) },
            removeLink: nodeActions.removeLink,
            removeSharing: nodeActions.removeSharing,
            rename: {
                nodeActions.rename(
                    $0, { [weak nodeBrowserViewModel] in
                        nodeBrowserViewModel?.refreshTitle()
                    }
                )
            },
            leaveSharing: nodeActions.leaveSharing,
            nodeSource: nodeSource
        )
        
        let rubbishBinMenuDelegate = RubbishBinMenuDelegateHandler(
            restore: { nodeActions.restoreFromRubbishBin([$0]) },
            showNodeInfo: nodeActions.showNodeInfo,
            showNodeVersions: nodeActions.showNodeVersions,
            remove: { nodeActions.removeFromRubbishBin([$0]) },
            nodeSource: nodeSource
        )

        let uploadAddMenuDelegate = UploadAddMenuDelegateHandler(
            nodeInsertionRouter: makeCloudDriveNodeInsertionRouter(),
            nodeSource: nodeSource
        )

        let contextMenuManager = ContextMenuManager(
            displayMenuDelegate: displayMenuDelegateHandler,
            quickActionsMenuDelegate: quickActionsMenuDelegateHandler,
            uploadAddMenuDelegate: uploadAddMenuDelegate,
            rubbishBinMenuDelegate: rubbishBinMenuDelegate,
            createContextMenuUseCase: createContextMenuUseCase
        )
        
        return (contextMenuManager, contextMenuManager.allNonNilActionHandlers())
    }

    private func open(node: NodeEntity) {
        Task { @MainActor in
            router.didTapNode(nodeHandle: node.handle)
        }
    }

    // this method is ripe for extracting to separate file
    // not doing this now as 2 develops are actively working with this file
    // This factory should be split into 2 , one that just creates new , one that just creates old CDVC
    private func newCloudDriveViewController(
        nodeSource: NodeSource,
        config: NodeBrowserConfig
    ) -> UIViewController {
        // overriding might be pulled level up,
        // it's an nil safe check for root node basically
        // it would be very much useful to make media discovery work with
        // MEGARecentActionBucket to load arbitrary list of nodes
        let overriddenConfig = makeOverriddenConfigIfNeeded(
            nodeSource: nodeSource,
            config: config
        )
        
        // this object will communicate from views showing the nodes
        // into search hosting controller which will configure the tool bar with items
        // depending on the context, selection state and selected items
        let selectionHandler = SearchControllerSelectionHandler()
        let isBackupsNode: () -> Bool = {
            guard
                case let .node(nodeProvider) = nodeSource,
                let node = nodeProvider()
            else { return false }
            return backupsUseCase.isBackupNode(node)
        }
        
        let toolbarActionCompleted: (BottomToolbarAction) -> Void = { _ in
            // here we should disable edit mode I think
        }
        
        let parentNodeAccessType: () async -> NodeAccessTypeEntity = {
            guard
                case let .node(nodeProvider) = nodeSource,
                let node = nodeProvider()
            else { return .unknown }
            return await accessType(for: node)
        }
        
        let toolbarConfig: (_ selectedNodes: [NodeEntity], _ accessType: NodeAccessTypeEntity) -> BottomToolbarConfig = { nodes, accessType in
                .init(
                    accessType: accessType,
                    displayMode: overriddenConfig.displayMode ?? .cloudDrive,
                    isBackupNode: isBackupsNode(),
                    selectedNodes: nodes,
                    isIncomingShareChildView: false,
                    onActionCompleted: toolbarActionCompleted
                )
        }
        
        let initialViewMode = viewModeFactory.determineInitialViewMode(
            nodeSource: nodeSource,
            config: overriddenConfig,
            hasOnlyMediaNodesChecker: CloudDriveViewControllerMediaCheckerMode.containsExclusivelyMedia.makeVisualMediaPresenceChecker(
                nodeSource: nodeSource,
                nodeUseCase: nodeUseCase
            )
        )

        let searchResultsVM = makeSearchResultsViewModel(
            nodeSource: nodeSource, 
            initialViewMode: initialViewMode,
            config: overriddenConfig
        )
        
        let searchControllerWrapper = SearchControllerWrapper(
            onSearch: { searchResultsVM.bridge.queryChanged($0) },
            onCancel: { searchResultsVM.bridge.queryCleaned() }
        )
        
        searchResultsVM.bridge.selectionChanged = { selectedNodes in
            let nodes: [NodeEntity] = selectedNodes.compactMap {
                nodeUseCase.nodeForHandle($0)
            }
            Task { @MainActor in
                let accessType = await parentNodeAccessType()
                selectionHandler.onSelectionChanged?(
                    toolbarConfig(nodes, accessType)
                )
            }
        }
        
        let onSelectionModeChange: (Bool) -> Void  = { enabled in
            
            Task { @MainActor in
                let accessType = await parentNodeAccessType()
                selectionHandler.onSelectionModeChange?(
                    enabled, toolbarConfig([], accessType)
                )
            }
        }

        let initialSortOrder = sortOrderPreferenceUseCase.sortOrder(for: nodeSource.parentNode)

        let mediaContentDelegate = MediaContentDelegateHandler()
        let nodeBrowserViewModel = makeNodeBrowserViewModel(
            initialViewMode: initialViewMode, 
            sortOrder: initialSortOrder,
            nodeSource: nodeSource,
            searchResultsViewModel: searchResultsVM,
            config: overriddenConfig,
            nodeActions: nodeActions,
            navigationController: navigationController,
            mediaContentDelegate: mediaContentDelegate,
            searchControllerWrapper: searchControllerWrapper,
            onSelectionModeChange: onSelectionModeChange
        )
        
        mediaContentDelegate.selectedPhotosHandler = { selected, _ in
            Task { @MainActor in
                let accessType = await parentNodeAccessType()
                // here we send selected items and config to refresh toolbar inside
                // SearchBarUIHostingController
                selectionHandler.onSelectionChanged?(
                    toolbarConfig(selected, accessType)
                )
                // Here we trigger reload of nav bar title
                // when selecting items inside MediaContentDiscoveryView
                nodeBrowserViewModel.refreshTitle()
            }
        }
        
        let (contextMenuManager, actionHandlers) = makeContextMenuManager(
            nodeSource: nodeSource,
            nodeBrowserViewModel: nodeBrowserViewModel,
            navigationController: navigationController
        )
        
        nodeBrowserViewModel.actionHandlers.append(actionHandlers)
        nodeBrowserViewModel.actionHandlers.append(mediaContentDelegate)

        let view = NodeBrowserView(
            viewModel: nodeBrowserViewModel
        )
        
        let vc = SearchBarUIHostingController(
            rootView: view,
            wrapper: searchControllerWrapper,
            selectionHandler: selectionHandler,
            toolbarBuilder: CloudDriveBottomToolbarItemsFactory(
                sdk: sdk,
                nodeActionHandler: nodeActions.makeNodeActionsHandler(),
                actionFactory: ToolbarActionFactory()
            ),
            backButtonTitle: titleFor(
                nodeSource,
                config: overriddenConfig
            ),
            searchBarVisible: initialViewMode != .mediaDiscovery, 
            viewModeProvider: makeViewModeProvider(viewModel: nodeBrowserViewModel),
            displayModeProvider: makeDisplayModeProvider(viewModel: nodeBrowserViewModel)
        )

        let setNavItemsFactory = { [weak nodeBrowserViewModel] in
            let viewMode: ViewModePreferenceEntity = nodeBrowserViewModel?.viewMode ?? .list
            let isSelectionHidden = nodeBrowserViewModel?.isSelectionHidden ?? false
            let sortOrder = nodeBrowserViewModel?.sortOrder ?? initialSortOrder
            return CloudDriveViewControllerNavItemsFactory(
                nodeSource: nodeSource,
                config: config,
                currentViewMode: viewMode,
                contextMenuManager: contextMenuManager,
                contextMenuConfigFactory: contextMenuConfigFactory,
                nodeUseCase: nodeUseCase,
                isSelectionHidden: isSelectionHidden,
                sortOrder: sortOrder
            )
        }

        let onContextMenuRefresh: () -> Void = { [weak nodeBrowserViewModel] in
            nodeBrowserViewModel?.contextMenuViewFactory = NodeBrowserContextMenuViewFactory(
                makeNavItemsFactory: setNavItemsFactory
            )
        }

        assert(actionHandlers.isNotEmpty, "sanity check as they should not be deallocated")
        // setting the refreshMenu handler so that context menu handlers can trigger it
        actionHandlers
            .compactMap { $0 as? (any RefreshMenuTriggering) }
            .forEach { $0.refreshMenu = onContextMenuRefresh }

        nodeBrowserViewModel.contextMenuViewFactory = NodeBrowserContextMenuViewFactory(
            makeNavItemsFactory: setNavItemsFactory
        )
        return vc
    }
    
    // this should be run in async way as it's locking up with the SDK lock
    private func accessType(for node: NodeEntity?) async -> NodeAccessTypeEntity {
        await nodeUseCase.nodeAccessLevelAsync(nodeHandle: node?.handle ?? .invalid)
    }
    
    private func makeOptionalWarningViewModel(
        _ nodeSource: NodeSource,
        config: NodeBrowserConfig
    ) -> WarningViewModel? {
        guard case let .node(parentNodeProvider) = nodeSource,
              config.isFromUnverifiedContactSharedFolder == true || config.warningViewModel != nil
        else {
            return nil
        }
        
        if config.isFromUnverifiedContactSharedFolder == true {
            return makeWarningViewModel(warningType: .contactNotVerifiedSharedFolder(parentNodeProvider()?.name ?? ""))
        } else if let warningViewModel = config.warningViewModel {
            return makeWarningViewModel(warningType: .backupStatusError(warningViewModel.warningType.description))
        }
        
        return nil
    }
    
    private func makeOverriddenConfigIfNeeded(
        nodeSource: NodeSource,
        config: NodeBrowserConfig
    ) -> NodeBrowserConfig {
        
        switch nodeSource {
        case .node(let parentNodeProvider):
            var overriddenConfig = config
            // overriding the config before passing to the NodeBrowserView
            // to make async checking for optional nodes possible, this is needed to be
            // able to launch the app in the offline mode, during which, root node is nil
            overriddenConfig.mediaDiscoveryAutomaticDetectionEnabled = {
                guard
                    let node = parentNodeProvider(),
                    node.nodeType != .root
                else {
                    return false
                }
                
                if config.displayMode == .rubbishBin {
                    return false
                }
                
                return preferences[.shouldDisplayMediaDiscoveryWhenMediaOnly] ?? true
            }
            return overriddenConfig
        case .recentActionBucket:
            return config
        }
    }
    
    private func makeSearchResultsViewModel(
        nodeSource: NodeSource,
        initialViewMode: ViewModePreferenceEntity,
        config: NodeBrowserConfig
    ) -> SearchResultsViewModel {
        // not all actions are triggered using bridge yet
        let bridge = SearchResultsBridge()
        
        // display mode is pass down through the folder hierarchy for rubbish bin and backups
        // this makes sure the actions that can be performed on the nodes
        // are valid
        let carriedOverDisplayMode = config.displayMode?.carriedOverDisplayMode
        
        let layout: PageLayout = {
            if initialViewMode == .thumbnail {
                .thumbnail
            } else {
                .list
            }
        }()
        
        let searchBridge = SearchBridge(
            selection: {
                router.didTapNode(
                    nodeHandle: $0.result.id,
                    // the siblings of the selected node are critical to be injected,
                    // for several features of the app to function, like
                    // audio player and image gallery
                    // for more details inspect NodeOpener.swift and it's openNode method
                    allNodeHandles: $0.nonEmptyOrNilSiblingsIds(),
                    displayMode: config.displayMode?.carriedOverDisplayMode, 
                    isFromSharedItem: false,
                    warningViewModel: config.warningViewModel
                )
            },
            context: { result, button in
                router.didTapMoreAction(
                    on: result.id,
                    button: button,
                    displayMode: carriedOverDisplayMode
                )
            },
            resignKeyboard: { [weak bridge] in
                bridge?.hideKeyboard()
            },
            chipTapped: { _, _ in},
            sortingOrder: { @MainActor in
                sortOrderPreferenceUseCase.sortOrder(for: nodeSource.parentNode).toSearchSortOrderEntity()
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

        return SearchResultsViewModel(
            resultsProvider: resultProvider(
                for: nodeSource,
                searchBridge: searchBridge
            ),
            bridge: searchBridge,
            config: .searchConfig(
                contextPreviewFactory: homeScreenFactory.contextPreviewFactory(
                    enableItemMultiSelection: true
                ),
                defaultEmptyViewAsset: { makeDefaultEmptyViewAsset(for: nodeSource, config: config) }
            ),
            layout: layout,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default)
        )
    }

    private func makeDefaultEmptyViewAsset(
        for nodeSource: NodeSource,
        config: NodeBrowserConfig
    ) -> SearchConfig.EmptyViewAssets {
        CloudDriveEmptyViewAssetFactory(
            nodeInsertionRouter: makeCloudDriveNodeInsertionRouter(),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            )
        )
        .defaultAsset(for: nodeSource, config: config)
    }

    private func makeCloudDriveNodeInsertionRouter() -> CloudDriveNodeInsertionRouter {
        CloudDriveNodeInsertionRouter(navigationController: navigationController, openNodeHandler: open(node:))
    }

    private func makeWarningViewModel(warningType: WarningType) -> WarningViewModel {
        WarningViewModel(warningType: warningType)
    }
    
    private func makeWarningViewModel(parentNodeProvider: ParentNodeProvider) -> WarningViewModel {
        WarningViewModel(warningType: .contactNotVerifiedSharedFolder(parentNodeProvider()?.name ?? ""))
    }
    
    private func resultProvider(
        for nodeSource: NodeSource,
        searchBridge: SearchBridge
    ) -> any SearchResultsProviding {
        switch nodeSource {
        case .node(let nodeProvider):
            homeScreenFactory.makeResultsProvider(
                parentNodeProvider: nodeProvider,
                searchBridge: searchBridge
            )
        case .recentActionBucket(let bucket):
            RecentActionBucketProvider(
                bucket: bucket,
                mapper: resultsMapper
            )
        }
    }
    
    private func locationFor(_ nodeSource: NodeSource) -> ViewModeLocation_ObjWrapper {
        switch nodeSource {
        case .node(let nodeProvider):
            // this is to remember layout per folder
            guard
                let parentNode = nodeProvider(),
                let megaNode = sdk.node(forHandle: parentNode.handle)
            else {
                return .init(customLocation: CustomViewModeLocation.Generic)
            }
            return .init(node: megaNode)
        case .recentActionBucket:
            return .init(customLocation: CustomViewModeLocation.Generic)
        }
    }
    
    private func titleFor(
        _ nodeSource: NodeSource,
        config: NodeBrowserConfig,
        isEditModeActive: Bool = false,
        selectedNodesArrayCount: Int = 0
    ) -> String? {
        switch nodeSource {
        case .node(let parentNodeProvider):
            guard let parentNodeProvider = parentNodeProvider() else { return nil }
            return CloudDriveNavigationTitleBuilder.build(
                parentNode: parentNodeProvider,
                isEditModeActive: isEditModeActive,
                // we have config.displayMode == nil for cloud drive
                displayMode: config.displayMode ?? .cloudDrive,
                selectedNodesArrayCount: selectedNodesArrayCount,
                // we don't use new CD for recents that's why we don't need to pass nodes here
                nodes: nil,
                backupsUseCase: BackupsUseCase(
                    backupsRepository: BackupsRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo
                )
            )
        default:
            return nil
        }
    }
    
    private func makeOptionalMediaDiscoveryViewModel(
        nodeSource: NodeSource,
        mediaContentDelegate: MediaContentDelegateHandler,
        isShowingAutomatically: Bool
    ) -> MediaDiscoveryContentViewModel? {
        guard case let .node(parentNodeProvider) = nodeSource else { return nil }
        
        return makeMediaDiscoveryViewModel(
            parentNodeProvider: parentNodeProvider,
            mediaContentDelegate: mediaContentDelegate,
            isShowingAutomatically: isShowingAutomatically
        )
    }
    
    private func makeMediaDiscoveryViewModel(
        parentNodeProvider: @escaping ParentNodeProvider,
        mediaContentDelegate: MediaContentDelegateHandler,
        isShowingAutomatically: Bool
    ) -> MediaDiscoveryContentViewModel {
        .init(
            contentMode: .mediaDiscovery,
            parentNodeProvider: parentNodeProvider,
            // Sorting to be handled in [FM-1776]
            // sortOrder: viewModel.sortOrder(for: .mediaDiscovery),
            sortOrder: .nameAscending,
            isAutomaticallyShown: isShowingAutomatically,
            delegate: mediaContentDelegate,
            analyticsUseCase: mediaAnalyticsUseCase,
            mediaDiscoveryUseCase: mediaDiscoveryUseCase
        )
    }
    
    /// This is to be injected into the SearchBarUIHostingController to server the Quick Upload feature.
    private func makeViewModeProvider(viewModel: NodeBrowserViewModel) -> CloudDriveViewModeProvider {
        CloudDriveViewModeProvider { [weak viewModel] in
            viewModel?.viewMode
        }
    }
    
    /// This is to be injected into the SearchBarUIHostingController to server the Ads slot feature.
    private func makeDisplayModeProvider(viewModel: NodeBrowserViewModel) -> CloudDriveDisplayModeProvider {
        CloudDriveDisplayModeProvider { [weak viewModel] in
            viewModel?.config.displayMode
        }
    }
}
