import Foundation
import MEGADomain
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
    /// when app is started offline, root node of the sdk is nil,
    /// but we need to have a way to attempt to re-aquire the node
    /// later when the app becomes connected
    case node(ParentNodeProvider)
    /// Can't use modern RecentActionBucketEntity as currently there's no way
    /// to create MEGARecentActionBucket from RecentActionBucketEntity [like we do with nodes]
    /// which is needed in the legacy CloudDriveViewController implementation
    case recentActionBucket(MEGARecentActionBucket)
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
    private let nodeRepository: any NodeRepositoryProtocol
    private let preferences: any PreferenceUseCaseProtocol
    private let resultsMapper: SearchResultMapper
    private let sdk: MEGASdk
    private let userDefaults: UserDefaults
    private let avatarViewModel: MyAvatarViewModel
    private let userProfileOpener: (UINavigationController) -> Void

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
        nodeRepository: some NodeRepositoryProtocol,
        preferences: some PreferenceUseCaseProtocol,
        sdk: MEGASdk,
        userDefaults: UserDefaults,
        userProfileOpener: @escaping (UINavigationController) -> Void
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
        self.nodeRepository = nodeRepository
        self.preferences = preferences
        self.sdk = sdk
        self.userDefaults = userDefaults
        self.userProfileOpener = userProfileOpener

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
                nodeUseCase: homeFactory.makeNodeUseCase(),
                mediaUseCase: homeFactory.makeMediaUseCase()
            ),
            nodeRepository: NodeRepository.newRepo,
            preferences: PreferenceUseCase.default,
            sdk: sdk,
            userDefaults: .standard,
            userProfileOpener: { navigationController in
                MyAccountHallRouter(
                    myAccountHallUseCase: MyAccountHallUseCase(repository: AccountRepository.newRepo),
                    purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
                    shareUseCase: ShareUseCase(repo: ShareRepository.newRepo),
                    networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
                    navigationController: navigationController
                ).start()
            }
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

    private func newCloudDriveViewController(
        nodeSource: NodeSource,
        config: NodeBrowserConfig
    ) -> UIViewController {
        // overriding might be pulled level up,
        // it's an nil safe check for root node basically
        // it would be very much useful to make media discovery work with
        // MEGARecentActionBucket to load arbitrary list of nodes
        let overriddenConfig = makeOverriddenConfigIfNeeded(nodeSource: nodeSource, config: config)
        let searchResultsVM = self.makeSearchResultsViewModel(
            nodeSource: nodeSource,
            config: overriddenConfig
        )
        let searchControllerWrapper = SearchControllerWrapper(
            onSearch: { searchResultsVM.bridge.queryChanged($0) },
            onCancel: { searchResultsVM.bridge.queryCleaned() }
        )
        let view = NodeBrowserView(
            viewModel: .init(
                searchResultsViewModel: searchResultsVM,
                mediaDiscoveryViewModel: self.makeOptionalMediaDiscoveryViewModel(nodeSource),
                warningViewModel: self.makeOptionalWarningViewModel(
                    nodeSource,
                    isFromUnverifiedContactSharedFolder: config.isFromUnverifiedContactSharedFolder == true
                ),
                config: overriddenConfig,
                nodeSource: nodeSource,
                avatarViewModel: self.avatarViewModel,
                hasOnlyMediaNodesChecker: self.makeHasOnlyMediaChecker(nodeSource: nodeSource),
                onOpenUserProfile: { self.userProfileOpener(self.navigationController) },
                onUpdateSearchBarVisibility: { searchControllerWrapper.onUpdateSearchBarVisibility?($0) },
                onBack: { self.navigationController.popViewController(animated: true) }
            )
        )
        let vc = SearchBarUIHostingController(
            rootView: view,
            wrapper: searchControllerWrapper
        )
        return vc
    }
    
    private func makeHasOnlyMediaChecker(nodeSource: NodeSource) -> () async -> Bool {
        switch nodeSource {
        case .node(let provider):
            // in here we produce a closure that can asynchronously check
            // if given folder node contains only media (videos/images)
            return {
                guard
                    let node = provider(),
                    let children = await nodeRepository.children(of: node)
                else { return false }
                
                return children.containsOnlyVisualMedia()
            }
        case .recentActionBucket:
            return { false }
        }
    }
    
    private func makeOptionalMediaDiscoveryViewModel(_ nodeSource: NodeSource) -> MediaDiscoveryContentViewModel? {
        guard case let .node(parentNodeProvider) = nodeSource else { return nil }
        
        return makeMediaDiscoveryViewModel(
            parentNodeProvider: parentNodeProvider,
            isShowingAutomatically: false // this is set later in .task modifier when we decide if need to show the banner explaining automatic MD presentation
        )
    }

    private func makeOptionalWarningViewModel(
        _ nodeSource: NodeSource,
        isFromUnverifiedContactSharedFolder: Bool
    ) -> WarningViewModel? {
        guard case let .node(parentNodeProvider) = nodeSource,
              isFromUnverifiedContactSharedFolder
        else {
            return nil
        }

        return makeWarningViewModel(parentNodeProvider: parentNodeProvider)
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
                    nodeHandle: $0.id,
                    allNodeHandles: nil,
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
    
    private func makeMediaDiscoveryViewModel(
        parentNodeProvider: @escaping ParentNodeProvider,
        isShowingAutomatically: Bool
    ) -> MediaDiscoveryContentViewModel {
            .init(
            contentMode: .mediaDiscovery,
            parentNodeProvider: parentNodeProvider,
            //            sortOrder: viewModel.sortOrder(for: .mediaDiscovery),
            sortOrder: .nameAscending,
            isAutomaticallyShown: isShowingAutomatically,
            delegate: MediaContentDelegate(),
            analyticsUseCase: mediaAnalyticsUseCase,
            mediaDiscoveryUseCase: mediaDiscoveryUseCase
        )
    }
}

// Implementing of the selection of nodes
// will be implemented here [FM-1463]
class MediaContentDelegate: MediaDiscoveryContentDelegate {
    func selectedPhotos(selected: [MEGADomain.NodeEntity], allPhotos: [MEGADomain.NodeEntity]) {
        // Connect select photos action
    }
    
    func isMediaDiscoverySelection(isHidden: Bool) {
        // Connect media discovery selection action
    }
    
    func mediaDiscoverEmptyTapped(menuAction: EmptyMediaDiscoveryContentMenuAction) {
        // Connect empty tapped action
    }
}
