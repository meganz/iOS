import Foundation
import MEGADomain
import MEGAPresentation
import MEGARepo
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

struct CloudDriveViewControllerFactory {
    
    struct NodeBrowserConfig {
        var displayMode: DisplayMode?
        var isFromViewInFolder: Bool?
        var isFromUnverifiedContactSharedFolder: Bool?
        var isFromSharedItem: Bool?
        var showsAvatar: Bool?
        var shouldRemovePlayerDelegate: Bool?
        
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
    
    let featureFlagProvider: any FeatureFlagProviderProtocol
    let abTestProvider: any ABTestProviderProtocol
    let navigationController: UINavigationController
    let viewModeStore: any ViewModeStoring
    let router: any NodeRouting
    let tracker: any AnalyticsTracking
    let homeScreenFactory: HomeScreenFactory
    let sdk: MEGASdk
    let userDefaults: UserDefaults
    
    init(
        featureFlagProvider: some FeatureFlagProviderProtocol,
        abTestProvider: some ABTestProviderProtocol,
        navigationController: UINavigationController,
        viewModeStore: some ViewModeStoring,
        router: some NodeRouting,
        tracker: some AnalyticsTracking,
        homeScreenFactory: HomeScreenFactory,
        sdk: MEGASdk,
        userDefaults: UserDefaults
    ) {
        self.featureFlagProvider = featureFlagProvider
        self.abTestProvider = abTestProvider
        self.navigationController = navigationController
        self.viewModeStore = viewModeStore
        self.router = router
        self.tracker = tracker
        self.homeScreenFactory = homeScreenFactory
        self.sdk = sdk
        self.userDefaults = userDefaults
    }
    
    static func make(nc: UINavigationController? = nil) -> Self {
        let sdk = MEGASdk.shared
        let factory = HomeScreenFactory()
        let tracker = DIContainer.tracker
        
        let navController = nc ?? MEGANavigationController(rootViewController: UIViewController())
        
        let router = factory.makeRouter(
            navController: navController,
            tracker: tracker
        )
        
        return .init(
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
            homeScreenFactory: factory,
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
        options: NodeBrowserConfig = .default
    ) -> UIViewController? {
        buildBare(nodeSource: .node({ parentNode }), options: options)
    }
    
    func build(
        rootNodeProvider: @escaping ParentNodeProvider,
        options: NodeBrowserConfig
    ) -> UIViewController? {
        build(nodeSource: .node(rootNodeProvider), options: options)
    }
    
    func build(
        parentNode: NodeEntity,
        options: NodeBrowserConfig
    ) -> UIViewController? {
        build(nodeSource: .node({ parentNode }), options: options)
    }
    
    func buildBare(
        nodeSource: NodeSource,
        options: NodeBrowserConfig
    ) -> UIViewController? {
        if useNewCloudDrive {
            return new(nodeSource, options)
        } else {
            return legacy(nodeSource, options)
        }
    }
    
    func build(
        nodeSource: NodeSource,
        options: NodeBrowserConfig
    ) -> UIViewController? {
        guard
            let vc = buildBare(nodeSource: nodeSource, options: options)
        else { return navigationController }
        
        navigationController.viewControllers = [vc]
        navigationController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage.cloudDriveIcon,
            selectedImage: nil
        )
        
        if 
            let legacy = vc as? (any MyAvatarPresenterProtocol),
            options.showsAvatar == true {
            legacy.configureMyAvatarManager()
        }
        
        return navigationController
    }
    
    private func new(_ nodeSource: NodeSource, _ options: NodeBrowserConfig) -> UIViewController {
        // not all actions are triggered using bridge yet
        let bridge = SearchResultsBridge()
        let searchBridge = SearchBridge(
            selection: {
                router.didTapNode($0.id, displayMode: options.displayMode?.carriedOverDisplayMode)
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
        
        let vm = SearchResultsViewModel(
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
        return UIHostingController(rootView: SearchResultsView(viewModel: vm))
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
    
    private func legacy(_ nodeSource: NodeSource, _ options: NodeBrowserConfig) -> UIViewController? {
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
}
