import Favourites
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import SwiftUI
import UIKit

public struct HomeView: View {
    private enum NavigationRoute: Hashable {
        case shortcut(ShortcutType)
    }

    public struct Dependency {
        let homeAddMenuActionHandler: any HomeAddMenuActionHandling
        let router: any HomeViewRouting
        let fullNameHandler: @Sendable (CurrentUserSource) -> String
        let userImageUseCase: any UserImageUseCaseProtocol
        let avatarFetcher: @Sendable () async -> Image?
        let fileSearchUseCase: any FilesSearchUseCaseProtocol
        let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
        let favouritesSearchResultsMapper: any FavouritesSearchResultsMapping
        let downloadedNodesListener: any DownloadedNodesListening
        let nodeUseCase: any NodeUseCaseProtocol
        let favouritesContextAction: @MainActor (HandleEntity, UIButton) -> Void
        let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
        let favouritesNodesActionHandler: any NodesActionHandling
        let onFavouritesEditingChanged: @MainActor (Bool) -> Void

        public init(
            homeAddMenuActionHandler: some HomeAddMenuActionHandling,
            router: some HomeViewRouting,
            fullNameHandler: @escaping @Sendable (CurrentUserSource) -> String,
            userImageUseCase: some UserImageUseCaseProtocol,
            avatarFetcher: @escaping @Sendable () async -> Image?,
            fileSearchUseCase: some FilesSearchUseCaseProtocol,
            sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
            favouritesSearchResultsMapper: some FavouritesSearchResultsMapping,
            downloadedNodesListener: some DownloadedNodesListening,
            nodeUseCase: some NodeUseCaseProtocol,
            favouritesContextAction: @escaping @MainActor (HandleEntity, UIButton) -> Void,
            sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
            favouritesNodesActionHandler: some NodesActionHandling,
            onFavouritesEditingChanged: @escaping @MainActor (Bool) -> Void
        ) {
            self.homeAddMenuActionHandler = homeAddMenuActionHandler
            self.router = router
            self.fileSearchUseCase = fileSearchUseCase
            self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
            self.favouritesSearchResultsMapper = favouritesSearchResultsMapper
            self.downloadedNodesListener = downloadedNodesListener
            self.nodeUseCase = nodeUseCase
            self.fullNameHandler = fullNameHandler
            self.userImageUseCase = userImageUseCase
            self.avatarFetcher = avatarFetcher
            self.favouritesContextAction = favouritesContextAction
            self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
            self.favouritesNodesActionHandler = favouritesNodesActionHandler
            self.onFavouritesEditingChanged = onFavouritesEditingChanged
        }
    }

    @StateObject var viewModel = HomeViewModel()
    @State private var navigationPath = NavigationPath()
    private let dependency: Dependency

    public init(dependency: Dependency) {
        self.dependency = dependency
    }

    public var body: some View {
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
                        contextAction: dependency.favouritesContextAction,
                        sortOrderPreferenceUseCase: dependency.sortOrderPreferenceUseCase,
                        nodesActionHandler: dependency.favouritesNodesActionHandler,
                        onEditingChanged: dependency.onFavouritesEditingChanged
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
                        userImageUseCase: dependency.userImageUseCase,
                        avatarFetcher: dependency.avatarFetcher
                    )) {
                        dependency.router.route(to: .accountUpgrade)
                    }
                case .promotionalBanners:
                    PromotionalBannersWidgetView()
                }
            }
        }
    }
}
