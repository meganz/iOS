import Favourites
import MEGAConnectivity
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI
import UIKit

public struct HomeView: View {
    private enum NavigationRoute: Hashable {
        case shortcut(ShortcutType)
    }

    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var navigator = HomeNavigation()

    @State private var searchText = ""
    private let dependency: Dependency

    public init(dependency: Dependency) {
        self.dependency = dependency
    }
    
    public var body: some View {
        HomeSearchableView(searchBecameActive: $viewModel.isSearching) {
            content
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .environment(\.networkConnected, viewModel.isNetworkConnected)
        .task { await viewModel.onTask() }
    }
    
    var content: some View {
        NavigationStack(path: $navigator.path) {
            listContent
                .embedInScrollViewWithDirectionChangeHandler {
                    viewModel.hidesFloatingActionsButton = $0
                }
                .floatingButton(isHidden: viewModel.hidesFloatingActionsButton) {
                    viewModel.presentsSheet.toggle()
                }
                .sheet(isPresented: $viewModel.presentsSheet) {
                    HomeMenuActionsSheetView(
                                            actionHandler: dependency.homeAddMenuActionHandler,
                                            isPresented: $viewModel.presentsSheet
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
                .noInternetViewModifier(layout: .onTop)
                .background(TokenColors.Background.page.swiftUI)
                .snackBar($navigator.snackBar)
                .navigationTitle(Strings.Localizable.home)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HomeTransferIndicatorView(progress: viewModel.transferProgress)
                    }
                }
                .navigationDestination(for: NavigationRoute.self) { route in
                    navigationDestinationBuilder(with: route)
                }
        }
        .background(HomeBackButtonConfigurator())
        .tint(TokenColors.Icon.primary.swiftUI)
        .environmentObject(navigator)
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
                        onEditingChanged: dependency.onFavouritesEditingChanged,
                        nodeSelectionHandler: dependency.favouritesNodeSelectionAction,
                        onNodeActionPerformed: dependency.onFavouritesNodeActionPerformed
                    )
                )
            case .offline:
                EmptyView() // Handled by UIKit routing
            }
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
                        case .offline:
                            dependency.router.route(to: .shortcut(shortcutType))
                        }
                    }
                case .accountDetails:
                    AccountDetailsWidgetView(dependency: .init(
                        fullNameHandler: dependency.fullNameHandler,
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
                        dependency: RecentsWidgetView.Dependency(userNameProvider: dependency.userNameProvider),
                        addMenuActionHandler: dependency.homeAddMenuActionHandler
                    )
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
                searchResultNodeActionHandler: dependency.searchResultNodeActionHandler
            ),
            searchText: $searchText
        )
    }

    private var noInternetView: some View {
        NoInternetView(
            dependency: .init(homeViewRouter: dependency.router, offlineFilesUseCase: dependency.offlineFilesUseCase)
        )
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
