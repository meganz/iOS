import Foundation
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGARepo
import MEGASDKRepo
import MEGASwift
import Search
import SwiftUI
import UIKit

typealias ParentNodeProvider = () -> NodeEntity?

enum NodeSource {
    /// we are using a closure returning an optional entity as
    /// when app is started offline, root node of the SDK is nil,
    /// but we need to have a way to attempt to re-acquire the node
    /// later when the app becomes connected
    case node(ParentNodeProvider)
    /// Can't use modern RecentActionBucketEntity as currently there's no way
    /// to create MEGARecentActionBucket from RecentActionBucketEntity [like we do with nodes]
    /// which is needed in the legacy CloudDriveViewController implementation
    /// This NodeSource mode should be used to construct a mode
    /// of showing nodes like in recent mode of legacy cloud drive, used in the Home -> multiple Recents files
    /// which shows CloudDriveVC in sectioned table view mode
    /// see useNewCloudDrive method and [FM-1691]
    case recentActionBucket(MEGARecentActionBucket)
    
    var isRoot: Bool {
        switch self {
        case .node(let parentNodeProvider):
            let node = parentNodeProvider()
            return node?.nodeType == .root
        case .recentActionBucket:
            return false
        }
    }
}

extension DisplayMode {
    var carriedOverDisplayMode: DisplayMode? {
        // for those 2 special cases, we carry over the display mode so that children are configured properly
        // [bug in the comments in FM-1461]
        if self == .rubbishBin || self == .backup {
            return self
        }
        return nil
    }
}

struct NodeBrowserConfig {
    
    var displayMode: DisplayMode?
    var isFromViewInFolder: Bool?
    var isFromUnverifiedContactSharedFolder: Bool?
    var isFromSharedItem: Bool?
    var showsAvatar: Bool?
    var shouldRemovePlayerDelegate: Bool?
    var warningViewModel: WarningViewModel?
    // this should enabled for non-root nodes
    var mediaDiscoveryAutomaticDetectionEnabled: () -> Bool = { false }
    // Determines whether the NodeBrowserView should handle upgrade encouragement flow or not, default value is true
    var supportsUpgradeEncouragement: Bool = true
    static var `default`: Self {
        .init()
    }
    
    /// small helper function to make it easier to pass down and package display mode into a config
    /// display mode must be carried over into a child folder when presenting in rubbish or backups mode
    static func withOptionalDisplayMode(_ displayMode: DisplayMode?) -> Self {
        var config = Self.default
        config.displayMode = displayMode
        return config
    }
    
    static func withOptionalDisplayMode(_ displayMode: DisplayMode?, warningViewModel: WarningViewModel?) -> Self {
        var config = Self.default
        config.displayMode = displayMode
        config.warningViewModel = warningViewModel
        return config
    }
    
    static func withSupportsUpgradeEncouragement(_ supportsUpgradeEncouragement: Bool) -> Self {
        var config = Self.default
        config.supportsUpgradeEncouragement = supportsUpgradeEncouragement
        return config
    }
}

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
    private let resultsMapper: SearchResultMapper
    private let sdk: MEGASdk
    private let userDefaults: UserDefaults
    private let contextMenuConfigFactory: CloudDriveContextMenuConfigFactory
    private let backupsUseCase: any BackupsUseCaseProtocol
    private let avatarViewModel: MyAvatarViewModel
    private let nodeInfoRouter: NodeInfoRouter
    private let sharedItemsRouter: SharedItemsViewRouter
    private let nodeShareRouter: NodeShareRouter
    private let shareUseCase: any ShareUseCaseProtocol
    private let rubbishBinUseCase: any RubbishBinUseCaseProtocol
    private let nodeActions: NodeActions
    
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
        sdk: MEGASdk,
        userDefaults: UserDefaults,
        contextMenuConfigFactory: CloudDriveContextMenuConfigFactory,
        backupsUseCase: some BackupsUseCaseProtocol,
        nodeInfoRouter: NodeInfoRouter,
        sharedItemsRouter: SharedItemsViewRouter,
        nodeShareRouter: NodeShareRouter,
        shareUseCase: some ShareUseCaseProtocol,
        rubbishBinUseCase: some RubbishBinUseCaseProtocol,
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
        self.sdk = sdk
        self.userDefaults = userDefaults
        self.contextMenuConfigFactory = contextMenuConfigFactory
        self.backupsUseCase = backupsUseCase
        self.nodeInfoRouter = nodeInfoRouter
        self.nodeShareRouter = nodeShareRouter
        self.sharedItemsRouter = sharedItemsRouter
        self.shareUseCase = shareUseCase
        self.rubbishBinUseCase = rubbishBinUseCase
        self.nodeActions = nodeActions
        
        self.avatarViewModel = MyAvatarViewModel(
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
        
        self.avatarViewModel.inputs.viewIsReady()
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
                nodeDetailUseCase: homeFactory.makeNodeDetailUseCase(),
                nodeUseCase: nodeUseCase,
                mediaUseCase: homeFactory.makeMediaUseCase()
            ),
            nodeUseCase: nodeUseCase,
            preferences: PreferenceUseCase.default,
            sdk: sdk,
            userDefaults: .standard,
            contextMenuConfigFactory: CloudDriveContextMenuConfigFactory(
                backupsUseCase: backupsUseCase,
                nodeUseCase: nodeUseCase
            ),
            backupsUseCase: backupsUseCase,
            nodeInfoRouter: .init(
                navigationController: nc
            ),
            sharedItemsRouter: SharedItemsViewRouter(),
            nodeShareRouter: NodeShareRouter(
                viewController: nc
            ),
            shareUseCase: ShareUseCase(repo: ShareRepository.newRepo), 
            rubbishBinUseCase: DIContainer.rubbishBinUseCase,
            nodeActions: .makeActions(sdk: sdk, nc: nc)
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
            legacyCloudDriveViewController(
                nodeSource: nodeSource,
                options: config
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
        
        let searchResultsVM = makeSearchResultsViewModel(
            nodeSource: nodeSource,
            config: overriddenConfig
        )
        
        let searchControllerWrapper = SearchControllerWrapper(
            onSearch: { searchResultsVM.bridge.queryChanged($0) },
            onCancel: { searchResultsVM.bridge.queryCleaned() }
        )
        
        let upgradeEncouragementViewModel: UpgradeEncouragementViewModel? = config.supportsUpgradeEncouragement ? .init() : nil

        
        let mediaContentDelegate = MediaContentDelegate()
        
        let nodeBrowserViewModel = NodeBrowserViewModel(
            searchResultsViewModel: searchResultsVM,
                mediaDiscoveryViewModel: makeOptionalMediaDiscoveryViewModel(
                nodeSource: nodeSource,
                mediaContentDelegate: mediaContentDelegate
            ),
            warningViewModel: makeOptionalWarningViewModel(
                nodeSource,
                config: config
            ),
            upgradeEncouragementViewModel: upgradeEncouragementViewModel,
            config: overriddenConfig,
            nodeSource: nodeSource,
            avatarViewModel: avatarViewModel,
            hasOnlyMediaNodesChecker: makeVisualMediaChecker(nodeSource: nodeSource, mode: .containsExclusivelyMedia),
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
                    config: overriddenConfig,
                    isEditModeActive: isEditing,
                    selectedNodesArrayCount: selectedNodesCount
                ) ?? ""
            },
            onOpenUserProfile: { nodeActions.userProfileOpener(self.navigationController) },
            onUpdateSearchBarVisibility: { searchControllerWrapper.onUpdateSearchBarVisibility?($0) },
            onBack: { self.navigationController.popViewController(animated: true) }
        )
        
        let displayMenuDelegateHandler = DisplayMenuDelegateHandler(
            rubbishBinUseCase: rubbishBinUseCase,
            toggleSelection: { [weak nodeBrowserViewModel] in
                nodeBrowserViewModel?.toggleSelection()
            },
            changeViewMode: { [weak nodeBrowserViewModel] in
                nodeBrowserViewModel?.changeViewMode($0)
            }
        )
        
        nodeBrowserViewModel.mediaContentDelegate = mediaContentDelegate
        nodeBrowserViewModel.actionHandlers.append(displayMenuDelegateHandler)
        
        displayMenuDelegateHandler.presenterViewController = navigationController
        
        // nodeInfoRouter, sharedItemsRouter and nodeShareRouter used below are retained inside the closure
        // so that their lifetime is the same as Delegate itself, which is retained
        // by NodeBrowserViewMode
        let quickActionsMenuDelegateHandler = QuickActionsMenuDelegateHandler(
            showNodeInfo: {
                nodeInfoRouter.showInformation(for: $0)
            },
            manageShare: {
                nodeShareRouter.pushManageSharing(for: $0, on: navigationController)
            },
            shareFolders: { nodes in
                Task { @MainActor [shareUseCase] in
                    do {
                        _ = try await shareUseCase.createShareKeys(forNodes: nodes)
                        sharedItemsRouter.showShareFoldersContactView(withNodes: nodes)
                    } catch {
                        SVProgressHUD.showError(withStatus: error.localizedDescription)
                    }
                }
            },
            download: { nodes in
                let transfers = nodes.map {
                    CancellableTransfer(
                        handle: $0.handle,
                        name: nil,
                        appData: nil,
                        priority: false,
                        isFile: $0.isFile,
                        type: .download
                    )
                }
                nodeActions.nodeDownloader(transfers)
            },
            presentGetLink: { nodeActions.getLinkOpener($0) }, 
            copy: { nodeActions.copyNode($0) },
            removeLink: { nodeActions.removeLink($0) },
            removeSharing: { nodeActions.removeSharing($0) },
            rename: {
                nodeActions.rename(
                    $0, { [weak nodeBrowserViewModel] in
                        nodeBrowserViewModel?.refreshTitle()
                    }
                )
            },
            leaveSharing: { nodeActions.leaveSharing($0) },
            nodeSource: nodeSource
        )
        
        let rubbishBinMenuDelegate = RubbishBinMenuDelegateHandler(
            restore: { nodeActions.restoreFromRubbishBin($0) },
            showNodeInfo: { nodeInfoRouter.showInformation(for: $0) },
            showNodeVersions: { nodeActions.showNodeVersions($0) },
            remove: { nodeActions.remove($0) },
            nodeSource: nodeSource
        )
        
        let contextMenuManager = ContextMenuManager(
            displayMenuDelegate: displayMenuDelegateHandler,
            quickActionsMenuDelegate: quickActionsMenuDelegateHandler,
            uploadAddMenuDelegate: UploadAddMenuDelegateHandler(),
            rubbishBinMenuDelegate: rubbishBinMenuDelegate,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
        )
        
        nodeBrowserViewModel.actionHandlers.append(contextMenuManager)
        nodeBrowserViewModel.actionHandlers.append(quickActionsMenuDelegateHandler)
        nodeBrowserViewModel.actionHandlers.append(rubbishBinMenuDelegate)
        
        let view = NodeBrowserView(
            viewModel: nodeBrowserViewModel
        )
        let vc = SearchBarUIHostingController(
            rootView: view,
            wrapper: searchControllerWrapper,
            backButtonTitle: titleFor(
                nodeSource,
                config: overriddenConfig
            )
        )
        
        let setContextMenuButton = { [weak nodeBrowserViewModel] in
            let viewMode: ViewModePreferenceEntity = nodeBrowserViewModel?.viewMode ?? .list
            let isSelectionHidden = nodeBrowserViewModel?.isSelectionHidden ?? false
            Task { @MainActor in
                let navItems = await navItems(
                    nodeSource: nodeSource,
                    config: config,
                    currentViewMode: viewMode,
                    contextMenuManager: contextMenuManager,
                    isSelectionHidden: isSelectionHidden
                )
                vc.navigationItem.rightBarButtonItems = navItems.rightNavBarItems
            }
        }
        // setting the refreshMenu handler so that context menu handlers can trigger it
        displayMenuDelegateHandler.refreshMenu = setContextMenuButton
        quickActionsMenuDelegateHandler.refreshMenu = setContextMenuButton
        setContextMenuButton()
        
        return vc
    }
    
    // Private structure that carries actual button items
    // to enable pure function and testing
    struct NavItems {
        let leftBarButtonItem: UIBarButtonItem?
        let rightNavBarItems: [UIBarButtonItem]
        
        static let empty = NavItems(
            leftBarButtonItem: nil,
            rightNavBarItems: []
        )
    }
    
    @MainActor
    // Method produces properly configured (with icons, titles and menus)
    // navigation bar button items
    private func navItems(
        nodeSource: NodeSource,
        config: NodeBrowserConfig,
        currentViewMode: ViewModePreferenceEntity,
        contextMenuManager: ContextMenuManager,
        isSelectionHidden: Bool
    ) async -> NavItems {
        
        guard case let .node(nodeProvider) = nodeSource else {
            return .empty
        }
        
        let parentNode = nodeProvider()
        
        let hasMedia = await makeVisualMediaChecker(nodeSource: nodeSource, mode: .containsSomeMedia)()
        let accessType = nodeUseCase.nodeAccessLevel(nodeHandle: parentNode?.handle ?? .invalid)
        
        let menuConfig = contextMenuConfigFactory.contextMenuConfiguration(
            parentNode: parentNode,
            nodeAccessType: accessType,
            currentViewMode: currentViewMode,
            isSelectionHidden: isSelectionHidden,
            showMediaDiscovery: sharedShouldShowMediaDiscoveryContextMenuOption(
                mediaDiscoveryDetectionEnabled: !nodeSource.isRoot,
                hasMediaFiles: hasMedia,
                isFromSharedItem: config.isFromSharedItem == true,
                viewModePreference: currentViewMode
                
            ),
            sortOrder: .defaultAsc,
            displayMode: config.displayMode?.carriedOverDisplayMode ?? .cloudDrive,
            isFromViewInFolder: config.isFromViewInFolder == true
        )
        guard let menuConfig else {
            return .empty
        }
        
        guard let menu = contextMenuManager.contextMenu(with: menuConfig) else {
            fatalError("menu should be available")
        }
        
        let contextBarButtonItem = UIBarButtonItem(
            image: UIImage.moreNavigationBar,
            menu: menu
        )
        
        let makeLeftBarButtonItem: () -> UIBarButtonItem? = {
            // cancel button needs to be produced here when VC is presented modally
            // to enable dismissal
            nil
        }
        
        return .init(
            leftBarButtonItem: makeLeftBarButtonItem(),
            rightNavBarItems: [contextBarButtonItem]
        )
    }
    
    enum MediaCheckerMode {
        case containsExclusivelyMedia
        case containsSomeMedia
    }
    
    /// checks if children of  given node are all visual media (video/image) or if there is at least one media element
    /// used to decide if we need to show the media discovery mode automatically and if media discovery
    /// view mode option should be shown at all in the context menu
    private func makeVisualMediaChecker(
        nodeSource: NodeSource,
        mode: MediaCheckerMode
    ) -> () async -> Bool {
        switch nodeSource {
        case .node(let provider):
            // in here we produce a closure that can asynchronously check
            // if given folder node contains only media (videos/images)
            return {
                guard
                    let node = provider(),
                    let children = await nodeUseCase.childrenOf(node: node)
                else { return false }
                
                switch mode {
                case .containsExclusivelyMedia:
                    return children.containsOnlyVisualMedia()
                case .containsSomeMedia:
                    return children.containsVisualMedia()
                }
            }
        case .recentActionBucket:
            return { false }
        }
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
        config: NodeBrowserConfig
    ) -> SearchResultsViewModel {
        // not all actions are triggered using bridge yet
        let bridge = SearchResultsBridge()
        
        // display mode is pass down through the folder hierarchy for rubbish bin and backups
        // this makes sure the actions that can be performed on the nodes
        // are valid
        let carriedOverDisplayMode = config.displayMode?.carriedOverDisplayMode
        
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
            chipTapped: { _, _ in}
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
        
        return SearchResultsViewModel(
            resultsProvider: resultProvider(
                for: nodeSource,
                searchBridge: searchBridge
            ),
            bridge: searchBridge,
            config: .searchConfig(
                contextPreviewFactory: homeScreenFactory.contextPreviewFactory(
                    enableItemMultiSelection: true
                )
            ),
            layout: viewModeStore.viewMode(for: locationFor(nodeSource)).pageLayout ?? .list,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default)
        )
    }
    
    private func makeWarningViewModel(warningType: WarningType) -> WarningViewModel {
        WarningViewModel(warningType: warningType)
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
    
    private func legacyCloudDriveViewController(
        nodeSource: NodeSource,
        options: NodeBrowserConfig
    ) -> UIViewController? {
        let stroryboard = UIStoryboard(name: "Cloud", bundle: nil)
        guard let vc =
                stroryboard.instantiateViewController(withIdentifier: "CloudDriveID") as? CloudDriveViewController
        else { return nil }
        
        switch nodeSource {
        case .node(let nodeProvider):
            if
                let nodeEntity = nodeProvider(),
                let megaNode = sdk.node(forHandle: nodeEntity.handle)
            {
                vc.parentNode = megaNode
            }
        case .recentActionBucket(let bucket):
            vc.recentActionBucket = bucket
        }
        
        if let displayMode = options.displayMode {
            vc.displayMode = displayMode
        }
        if let isFromViewInFolder = options.isFromViewInFolder {
            vc.isFromViewInFolder = isFromViewInFolder
        }
        
        if let isFromUnverifiedContactSharedFolder = options.isFromUnverifiedContactSharedFolder {
            vc.isFromUnverifiedContactSharedFolder = isFromUnverifiedContactSharedFolder
        }
        
        if let isFromSharedItem = options.isFromSharedItem {
            vc.isFromSharedItem = isFromSharedItem
        }
        
        if let shouldRemovePlayerDelegate = options.shouldRemovePlayerDelegate {
            vc.shouldRemovePlayerDelegate = shouldRemovePlayerDelegate
        }
        
        if let warningViewModel = options.warningViewModel {
            vc.warningViewModel = warningViewModel
        }
        
        return vc
    }
    
    private func makeOptionalMediaDiscoveryViewModel(
        nodeSource: NodeSource,
        mediaContentDelegate: MediaContentDelegate
    ) -> MediaDiscoveryContentViewModel? {
        guard case let .node(parentNodeProvider) = nodeSource else { return nil }
        
        return makeMediaDiscoveryViewModel(
            parentNodeProvider: parentNodeProvider,
            mediaContentDelegate: mediaContentDelegate,
            isShowingAutomatically: false // this is set later in .task modifier when we decide if need to show the banner explaining automatic MD presentation
        )
    }
    
    private func makeMediaDiscoveryViewModel(
        parentNodeProvider: @escaping ParentNodeProvider,
        mediaContentDelegate: MediaContentDelegate,
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
}
