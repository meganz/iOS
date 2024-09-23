import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGARepo
import MEGASDKRepo
import MEGASwift
import MEGAUIKit
import Search
import SwiftUI

@MainActor
struct CloudDriveViewControllerFactory {
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let abTestProvider: any ABTestProviderProtocol
    private let navigationController: UINavigationController
    private let viewModeStore: any ViewModeStoring
    private let router: any NodeRouting
    private let tracker: any AnalyticsTracking
    private let mediaAnalyticsUseCase: any MediaDiscoveryAnalyticsUseCaseProtocol
    private let mediaDiscoveryUseCase: any MediaDiscoveryUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
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
    private let viewModeFactory: ViewModeFactory
    private let nodeSensitivityChecker: any NodeSensitivityChecking

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
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
        nodeActions: NodeActions,
        nodeSensitivityChecker: some NodeSensitivityChecking
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
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.nodeActions = nodeActions
        self.nodeSensitivityChecker = nodeSensitivityChecker

        self.avatarViewModel = MyAvatarViewModel(
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
        
        self.avatarViewModel.inputs.viewIsReady()
        
        viewModeFactory = ViewModeFactory(viewModeStore: viewModeStore)
    }
    
    static func make(nc: UINavigationController? = nil) -> CloudDriveViewControllerFactory {
        let sdk = MEGASdk.shared
        let homeFactory = HomeScreenFactory()
        let tracker = DIContainer.tracker
        
        let navController = nc ?? MEGANavigationController(rootViewController: UIViewController())
        
        let nodeActions = NodeActions.makeActions(
            sdk: sdk,
            navigationController: navController
        )
        
        let nodeUseCase = homeFactory.makeNodeUseCase()
        let backupsUseCase = BackupsUseCase(
            backupsRepository: BackupsRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
        
        let nodeActionViewControllerDelegate = NodeActionViewControllerGenericDelegate(
            viewController: navController,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: navController),
            nodeActionListener: { action in
                switch action {
                case .hide:
                    tracker.trackAnalyticsEvent(with: CloudDriveHideNodeMenuItemEvent())
                default:
                    break
                }
            })
        
        let router = HomeSearchResultRouter(
            navigationController: navController,
            nodeActionViewControllerDelegate: nodeActionViewControllerDelegate,
            backupsUseCase: backupsUseCase,
            nodeUseCase: nodeUseCase
        )
        
        let nodeAssetsManager = NodeAssetsManager.shared
        
        let featureFlagProvider = DIContainer.featureFlagProvider
        
        return CloudDriveViewControllerFactory(
            featureFlagProvider: featureFlagProvider,
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
                mediaUseCase: homeFactory.makeMediaUseCase(), 
                nodeActions: nodeActions,
                hiddenNodesFeatureEnabled: featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes)
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
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
            nodeActions: nodeActions,
            nodeSensitivityChecker: NodeSensitivityChecker(
                featureFlagProvider: DIContainer.featureFlagProvider,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                systemGeneratedNodeUseCase: SystemGeneratedNodeUseCase(
                    systemGeneratedNodeRepository: SystemGeneratedNodeRepository.newRepo
                ),
                sensitiveNodeUseCase: SensitiveNodeUseCase(
                    nodeRepository: NodeRepository.newRepo
                )
            )
        )
    }
    
    private func useNewCloudDrive(config: NodeBrowserConfig) -> Bool {
        // disable new Cloud Drive for recents as it's very different
        // config with sections, the ticket to implement the needed behaviour: [FM-1691]
        config.displayMode != .recents
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
        nodeSource: NodeSource,
        searchResultsViewModel: SearchResultsViewModel,
        noInternetViewModel: NoInternetViewModel,
        nodeSourceUpdatesListener: some CloudDriveNodeSourceUpdatesListening,
        nodesUpdateListener: some NodesUpdateListenerProtocol,
        cloudDriveViewModeMonitoringService: some CloudDriveViewModeMonitoring,
        nodeUseCase: some NodeUseCaseProtocol,
        config: NodeBrowserConfig,
        nodeActions: NodeActions,
        navigationController: UINavigationController,
        mediaContentDelegate: MediaContentDelegateHandler,
        searchControllerWrapper: SearchControllerWrapper,
        onSelectionModeChange: @escaping (Bool) -> Void,
        sortOrderProvider: @escaping () -> MEGADomain.SortOrderEntity,
        onNodeStructureChanged: @escaping () -> Void
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
            avatarViewModel: avatarViewModel, 
            noInternetViewModel: noInternetViewModel,
            nodeSourceUpdatesListener: nodeSourceUpdatesListener,
            nodesUpdateListener: nodesUpdateListener, 
            cloudDriveViewModeMonitoringService: cloudDriveViewModeMonitoringService, 
            nodeUseCase: nodeUseCase, 
            sensitiveNodeUseCase: SensitiveNodeUseCase(nodeRepository: NodeRepository.newRepo),
            accountStorageUseCase: AccountStorageUseCase(accountRepository: AccountRepository.newRepo),
            viewModeSaver: {
                guard let node = nodeSource.parentNode else { return }
                viewModeStore.save(viewMode: $0, for: .node(node))
            },
            storageFullModalAlertViewRouter: StorageFullModalAlertViewRouter(),
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
            },
            updateTransferWidgetHandler: {
                TransfersWidgetViewController.sharedTransfer().showWidgetIfNeeded()
            }, 
            sortOrderProvider: sortOrderProvider,
            onNodeStructureChanged: onNodeStructureChanged
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
            rename: { [weak nodeBrowserViewModel] in
                nodeActions.rename(
                    $0, {
                        nodeBrowserViewModel?.refreshTitle()
                    }
                )
            },
            leaveSharing: nodeActions.leaveSharing,
            hide: nodeActions.hide,
            unhide: nodeActions.unhide,
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
            tracker: tracker,
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

        let viewModeProvider = { nodeSource, hasOnlyMediaNodes in
            viewModeFactory.determineViewMode(
                nodeSource: nodeSource,
                config: makeOverriddenConfigIfNeeded(
                    nodeSource: nodeSource,
                    config: config
                ),
                hasOnlyMediaNodesChecker: { hasOnlyMediaNodes }
            )
        }

        let viewModeAsyncProvider: (NodeSource) async -> ViewModePreferenceEntity = { nodeSource in
            let hasOnlyMediaNodes = CloudDriveViewControllerMediaCheckerMode
                .containsExclusivelyMedia
                .makeVisualMediaPresenceChecker(
                    nodeSource: nodeSource,
                    nodeUseCase: nodeUseCase
                )()

            return await Task { @MainActor in
                viewModeProvider(nodeSource, hasOnlyMediaNodes)
            }.value
        }

        let initialViewMode = viewModeProvider(
            nodeSource,
            CloudDriveViewControllerMediaCheckerMode
                .containsExclusivelyMedia
                .makeVisualMediaPresenceChecker(
                    nodeSource: nodeSource,
                    nodeUseCase: nodeUseCase
                )()
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

        let onNodeStructureChanged = { [weak navigationController, weak searchResultsVM] in
            guard let navigationController, let searchResultsVM else { return }

            var removeVCFromStack = false
            navigationController.viewControllers.removeAll { vc in
                guard let searchBarUIHostingVC = vc as? NewCloudDriveViewController,
                      let parentNode = nodeSource.parentNode else {
                    return false
                }

                if searchBarUIHostingVC.matchingNodeProvider.matchingNode(parentNode) {
                    searchResultsVM.bridge.editingCancelled()
                    removeVCFromStack = true
                }

                return removeVCFromStack
            }
        }

        let noInternetViewModel = NoInternetViewModel(
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo)
        )
        
        let nodesUpdateListener = SDKNodesUpdateListenerRepository(sdk: sdk)

        let nodeSourceUpdatesListener = NewCloudDriveNodeSourceUpdatesListener(
            originalNodeSource: nodeSource,
            nodeUpdatesListener: nodesUpdateListener
        )

        let cloudDriveViewModeMonitoringService = CloudDriveViewModeMonitoringService(
            nodeSource: nodeSource,
            currentViewMode: initialViewMode,
            viewModeProvider: viewModeAsyncProvider
        )

        let mediaContentDelegate = MediaContentDelegateHandler()
        let nodeBrowserViewModel = makeNodeBrowserViewModel(
            initialViewMode: initialViewMode,
            nodeSource: nodeSource,
            searchResultsViewModel: searchResultsVM,
            noInternetViewModel: noInternetViewModel, 
            nodeSourceUpdatesListener: nodeSourceUpdatesListener,
            nodesUpdateListener: nodesUpdateListener, 
            cloudDriveViewModeMonitoringService: cloudDriveViewModeMonitoringService,
            nodeUseCase: nodeUseCase,
            config: overriddenConfig,
            nodeActions: nodeActions,
            navigationController: navigationController,
            mediaContentDelegate: mediaContentDelegate,
            searchControllerWrapper: searchControllerWrapper,
            onSelectionModeChange: onSelectionModeChange,
            sortOrderProvider: {
                sortOrderPreferenceUseCase.sortOrder(for: nodeSource.parentNode)
            }, 
            onNodeStructureChanged: onNodeStructureChanged
        )
        
        mediaContentDelegate.selectedPhotosHandler = { [weak nodeBrowserViewModel] selected, _ in
            guard let nodeBrowserViewModel else { return }
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
        
        let vc = NewCloudDriveViewController(
            rootView: view,
            wrapper: searchControllerWrapper,
            selectionHandler: selectionHandler,
            toolbarBuilder: CloudDriveBottomToolbarItemsFactory(
                sdk: sdk,
                nodeActionHandler: nodeActions.makeNodeActionsHandler(toggleEditMode: { [weak nodeBrowserViewModel] editing in
                    nodeBrowserViewModel?.setEditMode(editing)
                }),
                actionFactory: ToolbarActionFactory(),
                nodeUseCase: nodeUseCase,
                nodeAccessoryActionDelegate: DefaultNodeAccessoryActionDelegate()
            ),
            backButtonTitle: titleFor(
                nodeSource,
                config: overriddenConfig
            ),
            searchBarVisible: initialViewMode != .mediaDiscovery, 
            viewModeProvider: makeViewModeProvider(viewModel: nodeBrowserViewModel),
            displayModeProvider: makeDisplayModeProvider(viewModel: nodeBrowserViewModel), 
            matchingNodeProvider: makeMatchingNodeProvider(viewModel: nodeBrowserViewModel),
            audioPlayerManager: AudioPlayerManager.shared,
            parentNodeProvider: { nodeSource.parentNode }
        )

        let onContextMenuRefresh: () -> Void = {  [weak nodeBrowserViewModel] in
            Task { @MainActor [weak nodeBrowserViewModel] in
                await nodeBrowserViewModel?.updateContextMenu()
            }
        }

        assert(actionHandlers.isNotEmpty, "sanity check as they should not be deallocated")
        // setting the refreshMenu handler so that context menu handlers can trigger it
        actionHandlers
            .compactMap { $0 as? (any RefreshMenuTriggering) }
            .forEach { $0.refreshMenu = onContextMenuRefresh }

        nodeBrowserViewModel.cloudDriveContextMenuFactory = CloudDriveContextMenuFactory(
            config: config,
            contextMenuManager: contextMenuManager,
            contextMenuConfigFactory: contextMenuConfigFactory,
            nodeSensitivityChecker: nodeSensitivityChecker,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            nodeUseCase: nodeUseCase
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
    ) -> WarningBannerViewModel? {
        guard case let .node(parentNodeProvider) = nodeSource,
              config.isFromUnverifiedContactSharedFolder == true ||
              config.warningViewModel != nil ||
              config.storageQuotaStatusProvider() == .full
        else {
            return nil
        }
        
        if config.isFromUnverifiedContactSharedFolder == true {
            return makeWarningViewModel(warningType: .contactNotVerifiedSharedFolder(parentNodeProvider()?.name ?? ""))
        }
        
        if let warningViewModel = config.warningViewModel {
            return warningViewModel
        }
        
        return makeWarningViewModel(warningType: .fullStorageOverQuota)
    }
    
    private func makeOverriddenConfigIfNeeded(
        nodeSource: NodeSource,
        config: NodeBrowserConfig,
        isFullSOQBannerEnabled: @escaping () -> Bool = { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .fullStorageOverQuotaBanner) }
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
            
            // The Storage over quota banners should only be shown in the Cloud Drive.
            // The condition checks if the current view is not from a shared item.
            // If `isFromSharedItem` is `nil` or `false`, it means the current item is part of the Cloud Drive,
            // and thus, the storage over-quota banners should be displayed if applicable.
            if overriddenConfig.isFromSharedItem != true {
                overriddenConfig.storageQuotaStatusProvider = {
                    guard isFullSOQBannerEnabled() else { return .noStorageProblems }
                    let accountStorageUseCase = AccountStorageUseCase(accountRepository: AccountRepository.newRepo)
                    return accountStorageUseCase.currentStorageStatus
                }
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
                    isFromSharedItem: config.isFromSharedItem ?? false,
                    warningViewModel: config.warningViewModel
                )
            },
            context: { result, button in
                router.didTapMoreAction(
                    on: result.id,
                    button: button,
                    displayMode: carriedOverDisplayMode, 
                    isFromSharedItem: config.isFromSharedItem ?? false
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
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default),
            viewDisplayMode: config.displayMode?.toViewDisplayMode ?? .unknown
        )
    }

    private func makeDefaultEmptyViewAsset(
        for nodeSource: NodeSource,
        config: NodeBrowserConfig
    ) -> SearchConfig.EmptyViewAssets {
        CloudDriveEmptyViewAssetFactory(
            tracker: tracker,
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

    private func makeWarningViewModel(warningType: WarningBannerType) -> WarningBannerViewModel {
        WarningBannerViewModel(warningType: warningType)
    }
    
    private func makeWarningViewModel(parentNodeProvider: ParentNodeProvider) -> WarningBannerViewModel {
        WarningBannerViewModel(warningType: .contactNotVerifiedSharedFolder(parentNodeProvider()?.name ?? ""))
    }
    
    private func resultProvider(
        for nodeSource: NodeSource,
        searchBridge: SearchBridge
    ) -> any SearchResultsProviding {
        switch nodeSource {
        case .node(let nodeProvider):
            homeScreenFactory.makeResultsProvider(
                parentNodeProvider: nodeProvider,
                navigationController: navigationController
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
            mediaDiscoveryUseCase: mediaDiscoveryUseCase, 
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase
        )
    }
    
    /// This is to be injected into the NewCloudDriveViewController to server the Quick Upload feature.
    private func makeViewModeProvider(viewModel: NodeBrowserViewModel) -> CloudDriveViewModeProvider {
        CloudDriveViewModeProvider { [weak viewModel] in
            viewModel?.viewMode
        }
    }
    
    /// This is to be injected into the NewCloudDriveViewController to server the Ads slot feature.
    private func makeDisplayModeProvider(viewModel: NodeBrowserViewModel) -> CloudDriveDisplayModeProvider {
        CloudDriveDisplayModeProvider { [weak viewModel] in
            viewModel?.config.displayMode
        }
    }

    /// This is to be injected into the SearchBarUIHostingController to serve the changes to parent nodes structure
    private func makeMatchingNodeProvider(viewModel: NodeBrowserViewModel) -> CloudDriveMatchingNodeProvider {
        CloudDriveMatchingNodeProvider { [weak viewModel] node in
            viewModel?.parentNodeMatches(node: node) == true
        }
    }
}
