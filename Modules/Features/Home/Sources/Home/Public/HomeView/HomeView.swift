import Favourites
import MEGADesignToken
import MEGAL10n
import SwiftUI
import UIKit

public struct HomeView: View {
    private enum NavigationRoute: Hashable {
        case shortcut(ShortcutType)
    }

    @StateObject var viewModel = HomeViewModel()
    @State private var navigationPath = NavigationPath()

    @State private var searchText = "" // [IOS-11361]: Handle searching logic
    private let dependency: Dependency

    public init(dependency: Dependency) {
        self.dependency = dependency
    }
    
    public var body: some View {
        HomeSearchableView(searchBecameActive: $viewModel.isSearching) {
            content
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }
    
    var content: some View {
        NavigationStack(path: $navigationPath) {
            listContent
                .navigationTitle(Strings.Localizable.home)
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: NavigationRoute.self) { route in
                    navigationDestinationBuilder(with: route)
                }
                .embedInScrollViewWithDirectionChangeHandler {
                    viewModel.hidesFloatingActionsButton = $0
                }
                .floatingButton(isHidden: viewModel.hidesFloatingActionsButton) {
                    viewModel.presentsSheet.toggle()
                }
                .sheet(isPresented: $viewModel.presentsSheet) {
                    HomeMenuActionsSheetView(isPresented: $viewModel.presentsSheet, selection: $viewModel.selectedFloatingButtonAction)
                }
                .onReceive(viewModel.$selectedFloatingButtonAction.compactMap { $0 }) {
                    dependency.homeAddMenuActionHandler.handleAction($0)
                }
                .overlay {
                    if viewModel.isSearching {
                        searchContent
                    }
                }
        }
        .background(HomeBackButtonConfigurator())
        .tint(TokenColors.Icon.primary.swiftUI)
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
                        nodeSelectionHandler: dependency.favouritesNodeSelectionAction
                    )
                )
            case .offline, .videos:
                EmptyView() // Handled by UIKit routing
            }
        }
    }

    private var listContent: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.widgets) { widget in
                switch widget {
                case .shortcuts:
                    ShortcutsWidgetView { shortcutType in
                        switch shortcutType {
                        case .favourites:
                            navigationPath.append(NavigationRoute.shortcut(.favourites))
                        case .offline, .videos:
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
                }
            }
        }
    }

    // [IOS-11361]: Handle searching
    private var searchContent: some View {
        ZStack {
            Color.white
            Text("Search result goes here")
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
