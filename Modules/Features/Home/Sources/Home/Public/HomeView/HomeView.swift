import Combine
import Favourites
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI
import Transfer
import UIKit

@MainActor
public final class HomeDeepLink: ObservableObject {
    @Published public var homeSearch: Bool = false
    
    public init() {}
}

public struct HomeView: View {
    private enum NavigationRoute: Hashable {
        case shortcut(ShortcutType)
        case recents
        case widgetsCustomization
    }

    @StateObject private var viewModel: HomeViewModel
    @StateObject private var navigator: HomeNavigation
    @StateObject private var promotionalDialogViewModel = HomePromotionalDialogViewModel()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var searchText = ""
    private let quickAccessRoutePublisher: AnyPublisher<QuickAccessRoute?, Never>
    private let dependency: Dependency

    private var isIphoneInLandscape: Bool {
        verticalSizeClass == .compact
    }

    private var isLiquidGlassSupported: Bool {
        if #available(iOS 26.0, *) {
            true
        } else {
            false
        }
    }

    private var shouldAddLiquidGlassPadding: Bool {
        isLiquidGlassSupported && isIphoneInLandscape
    }

    private var isHomeRevampPhase2Enabled: Bool {
        dependency.featureFlagProvider.isFeatureFlagEnabled(for: .iosHomeRevampPhaseTwo)
    }

    public init(
        dependency: Dependency,
        homeDeepLink: HomeDeepLink,
        tabBarHidden: Binding<Bool>,
        quickAccessRoutePublisher: AnyPublisher<QuickAccessRoute?, Never>
    ) {
        self.dependency = dependency
        _viewModel = StateObject(wrappedValue: HomeViewModel(homeDeepLink: homeDeepLink, featureFlagProvider: dependency.featureFlagProvider))
        _navigator = StateObject(wrappedValue: HomeNavigation(tabBarHidden: tabBarHidden))
        self.quickAccessRoutePublisher = quickAccessRoutePublisher
    }

    public var body: some View {
        NavigationStack(path: $navigator.path) {
            content
        }
        .background(HomeBackButtonConfigurator())
            .tint(TokenColors.Icon.primary.swiftUI)
        .environmentObject(navigator)
        .environment(\.networkConnected, viewModel.isNetworkConnected)
        .task { await viewModel.monitorNetworkConnection() }
        .task { await viewModel.monitorSearchBarPressed() }
        .task { await viewModel.observeDeepLinkSearch() }
        .onReceive(quickAccessRoutePublisher.compactMap { $0 }) {
            switch $0 {
            case .recents:
                navigator.append(NavigationRoute.recents)
            case .offlines:
                dependency.router.route(to: .shortcut(.offline))
            case .offlineFile(let base64Handle):
                dependency.router.openOfflineFile(base64Handle: base64Handle)
            case .favourites:
                navigator.append(NavigationRoute.shortcut(.favourites))
            case .favouriteNode(let handle):
                dependency.router.openNode(base64Handle: handle)
            }
        }
        .sheet(isPresented: $promotionalDialogViewModel.isPresented, onDismiss: {
            if promotionalDialogViewModel.shouldNavigateToCustomizationAfterDismissal {
                navigator.append(NavigationRoute.widgetsCustomization)
            }
        }, content: {
            HomePromotionalDialogView(
                onExplore: { promotionalDialogViewModel.handleExplore() },
                onDismiss: { promotionalDialogViewModel.handleDismiss() }
            )
        })
    }

    var content: some View {
        listContent
            .searchableVisible(text: $searchText, isPresented: $viewModel.isSearching, placement: .navigationBarDrawer(displayMode: .always))
            .embedInScrollViewWithDirectionChangeHandler {
                viewModel.hidesFloatingActionsButton = $0
            }
            .floatingButton(isHidden: viewModel.hidesFloatingActionsButton) {
                viewModel.togglePresentHomeActionsSheet()
            }
            .sheet(isPresented: $viewModel.presentHomeActions) {
                HomeMenuActionsSheetView(
                                        actionHandler: dependency.homeAddMenuActionHandler,
                                        isPresented: $viewModel.presentHomeActions
                                    )
            }
            .overlay {
                if viewModel.isSearching {
                    searchContent
                }
            }
            .noNetworkConnection {
                noInternetView
            }
            .modifier(HomeLandscapeNoInternetViewModifier())
            .background(TokenColors.Background.page.swiftUI)
            .searchableTransitionWorkaround()
            .snackBar($navigator.snackBar)
            .navigationTitle(Strings.Localizable.home)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isHomeRevampPhase2Enabled {
                    dependency.transferIndicatorToolbarFactory.toolbarContent(trailingItemCount: 2)

                    if #available(iOS 26.0, *) {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                viewModel.isSearching = true
                            } label: {
                                Image(uiImage: MEGAAssets.UIImage.search)
                            }
                        }

                        ToolbarSpacer(.fixed, placement: .topBarTrailing)

                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                navigator.append(NavigationRoute.widgetsCustomization)
                            } label: {
                                Image(uiImage: MEGAAssets.UIImage.slidersVertical)
                            }
                        }
                    } else {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            Button {
                                viewModel.isSearching = true
                            } label: {
                                Image(uiImage: MEGAAssets.UIImage.search)
                            }

                            Button {
                                navigator.append(NavigationRoute.widgetsCustomization)
                            } label: {
                                Image(uiImage: MEGAAssets.UIImage.slidersVertical)
                            }
                        }
                    }
                } else {
                    dependency.transferIndicatorToolbarFactory.toolbarContent(trailingItemCount: 1)
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.isSearching = true
                        } label: {
                            Image(uiImage: MEGAAssets.UIImage.search)
                        }
                    }
                }
            }
            .miniPlayerAware()
            .navigationDestination(for: NavigationRoute.self) { route in
                navigationDestinationBuilder(with: route)
            }
            .task { viewModel.reloadWidgets() }
            .onAppear {
                viewModel.trackHomeScreenAppear()
                promotionalDialogViewModel.presentIfNeeded(featureEnabled: isHomeRevampPhase2Enabled)
            }
    }

    @ViewBuilder
    private func navigationDestinationBuilder(with route: NavigationRoute) -> some View {
        switch route {
        case let .shortcut(type):
            switch type {
            case .favourites:
                FavouritesView(
                    dependency: .init(
                        fileSearchUseCase: dependency.fileSearchUseCase,
                        sensitiveDisplayPreferenceUseCase: dependency.sensitiveDisplayPreferenceUseCase,
                        searchResultsMapper: dependency.favouritesSearchResultsMapper,
                        downloadedNodesListener: dependency.downloadedNodesListener,
                        nodeUseCase: dependency.nodeUseCase,
                        sortOrderPreferenceUseCase: dependency.sortOrderPreferenceUseCase,
                        nodesActionHandler: dependency.favouritesNodesActionHandler,
                        nodeSelectionHandler: dependency.favouritesNodeSelectionAction,
                        moreActionsPresenter: dependency.favouritesMoreActionsPresenter,
                        selectActionPublisher: dependency.favouritesSelectActionPublisher,
                        transferIndicatorToolbarFactory: dependency.transferIndicatorToolbarFactory
                    ),
                    tabBarHidden: $navigator.tabBarHidden
                )
            case .offline, .audios:
                EmptyView() // Handled by UIKit routing
            }
        case .recents:
            RecentActionBucketsListView(
                dependency: RecentActionBucketsListView.Dependency(
                    userNameProvider: dependency.userNameProvider,
                    recentActionBucketItemResultMapper: dependency.recentActionBucketItemResultMapper,
                    downloadedNodesListener: dependency.downloadedNodesListener,
                    selectionHandler: dependency.recentActionBucketNodeSelectionHandler,
                    nodeActionHandler: dependency.recentActionBucketNodesActionHandler,
                    moreActionsPresenter: dependency.recentActionBucketMoreActionsPresenter,
                    photoLibraryContentViewRouter: dependency.photoLibraryContentViewRouter,
                    transferIndicatorToolbarFactory: dependency.transferIndicatorToolbarFactory,
                    isHomeRevampPhaseTwoEnabled: isHomeRevampPhase2Enabled
                )
            )
        case .widgetsCustomization:
            HomeWidgetsCustomizationView()
        }
    }

    private var listContent: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.widgets) { widget in
                switch widget {
                case .shortcuts:
                    ShortcutsWidgetView { shortcutType in
                        switch shortcutType {
                        case .favourites:
                            navigator.append(NavigationRoute.shortcut(.favourites))
                        case .offline, .audios:
                            dependency.router.route(to: .shortcut(shortcutType))
                        }
                    }
                case .accountDetails:
                    AccountDetailsWidgetView(dependency: .init(
                        userNameProvider: dependency.userNameProvider,
                        avatarFetcher: dependency.avatarFetcher
                    )) {
                        dependency.router.route(to: .accountUpgrade)
                    }
                case .promotionalBanners:
                    PromotionalBannersWidgetView {
                        dependency.router.route(to: .promotionalBanner($0))
                    }
                case .recents:
                    RecentsWidgetView(
                        dependency: RecentsWidgetView.Dependency(
                            userNameProvider: dependency.userNameProvider,
                            recentActionBucketItemResultMapper: dependency.recentActionBucketItemResultMapper,
                            downloadedNodesListener: dependency.downloadedNodesListener,
                            selectionHandler: dependency.recentActionBucketNodeSelectionHandler,
                            nodeActionHandler: dependency.recentActionBucketNodesActionHandler,
                            moreActionsPresenter: dependency.recentActionBucketMoreActionsPresenter,
                            photoLibraryContentViewRouter: dependency.photoLibraryContentViewRouter,
                            transferIndicatorToolbarFactory: dependency.transferIndicatorToolbarFactory,
                            isHomeRevampPhaseTwoEnabled: dependency.featureFlagProvider.isFeatureFlagEnabled(for: .iosHomeRevampPhaseTwo)
                        ),
                        addMenuActionHandler: dependency.homeAddMenuActionHandler
                    )
                case .viewedLinks, .continueWhereYouLeft, .doMoreWithMega:
                    if isHomeRevampPhase2Enabled {
                        Text("\(widget.rawValue)") // corresponding view will be added later
                            .frame(height: 30)
                            .background([Color.red, Color.blue, Color.green].randomElement())
                    } else {
                        EmptyView()
                    }
                }
            }
        }
    }
    
    private var searchContent: some View {
        HomeSearchResultsView(
            dependency: HomeSearchResultsView.Dependency(
                searchConfig: SearchConfig.homeSearchConfig,
                resultsProvider: dependency.searchResultsProvider,
                searchResultsSelectionHandler: dependency.searchResultsSelectionHandler,
                searchResultNodeActionHandler: dependency.searchResultNodeActionHandler,
                tracker: dependency.tracker
            ),
            searchText: $searchText
        )
    }

    private var noInternetView: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack {
                    NoInternetView(
                        dependency: .init(homeViewRouter: dependency.router, offlineFilesUseCase: dependency.offlineFilesUseCase)
                    )
                }
                .frame(minHeight: proxy.size.height + (shouldAddLiquidGlassPadding ? proxy.safeAreaInsets.bottom : 0))
            }
            .scrollDisabled(!isIphoneInLandscape)
        }
    }
}

// Sets backButtonDisplayMode = .minimal on the NavigationStack's root view controller
// so that any pushed view (e.g. FavouritesView) shows only the chevron, not the "Home" title.
// Scoped to iOS < 26 because iOS 26 already hides the back button text natively.
private struct HomeBackButtonConfigurator: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> HomeBackButtonConfiguratorController {
        HomeBackButtonConfiguratorController()
    }

    func updateUIViewController(_ uiViewController: HomeBackButtonConfiguratorController, context: Context) {}
}

private final class HomeBackButtonConfiguratorController: UIViewController {
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        guard #unavailable(iOS 26) else { return }
        parent?.navigationItem.backButtonDisplayMode = .minimal
    }
}
