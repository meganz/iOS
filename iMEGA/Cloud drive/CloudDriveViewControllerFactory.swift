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
}

struct CloudDriveViewControllerFactory {
    
    let featureFlagProvider: any FeatureFlagProviderProtocol
    let abTestProvider: any ABTestProviderProtocol
    let navigationController: UINavigationController
    let viewModeStore: any ViewModeStoring
    let router: any NodeRouting
    let tracker: any AnalyticsTracking
    let mediaAnalyticsUseCase: any MediaDiscoveryAnalyticsUseCaseProtocol
    let mediaDiscoveryUseCase: any MediaDiscoveryUseCaseProtocol
    let homeScreenFactory: HomeScreenFactory
    let nodeRepository: any NodeRepositoryProtocol
    let preferences: any PreferenceUseCaseProtocol
    let sdk: MEGASdk
    let userDefaults: UserDefaults
    
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
        nodeRepository: some NodeRepositoryProtocol,
        preferences: some PreferenceUseCaseProtocol,
        sdk: MEGASdk,
        userDefaults: UserDefaults
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
        self.nodeRepository = nodeRepository
        self.preferences = preferences
        self.sdk = sdk
        self.userDefaults = userDefaults
    }
    
    static func make(nc: UINavigationController? = nil) -> CloudDriveViewControllerFactory {
        let sdk = MEGASdk.shared
        let factory = HomeScreenFactory()
        let tracker = DIContainer.tracker
        
        let navController = nc ?? MEGANavigationController(rootViewController: UIViewController())
        
        let router = factory.makeRouter(
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
            homeScreenFactory: factory,
            nodeRepository: NodeRepository.newRepo,
            preferences: PreferenceUseCase.default,
            sdk: sdk,
            userDefaults: .standard
        )
    }
    private var useNewCloudDrive: Bool {
        userDefaults.bool(forKey: Helper.cloudDriveABTestCacheKey()) ||
        featureFlagProvider.isFeatureFlagEnabled(for: .newCloudDrive)
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
        if useNewCloudDrive {
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
        
        let view = NodeBrowserView(
            viewModel: .init(
                searchResultsViewModel: makeSearchResultsViewModel(
                    nodeSource: nodeSource,
                    config: overriddenConfig
                ),
                mediaDiscoveryViewModel: makeOptionalMediaDiscoveryViewModel(nodeSource),
                config: overriddenConfig,
                hasOnlyMediaNodesChecker: makeHasOnlyMediaChecker(nodeSource: nodeSource)
            )
        )
        return UIHostingController(rootView: view)
    }
    
    private func makeHasOnlyMediaChecker(nodeSource: NodeSource) -> () async -> Bool {
        switch nodeSource {
        case .node(let provider):
            // in here we produce a closure that can asynchronously check
            // if given folder node contains only media (videos/images)
            return  {
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
        let searchBridge = SearchBridge(
            selection: {
                router.didTapNode($0.id, displayMode: config.displayMode?.carriedOverDisplayMode)
            },
            context: { result, button in
                router.didTapMoreAction(on: result.id, button: button)
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
            RecentActionBucketProvider(bucket: bucket)
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
