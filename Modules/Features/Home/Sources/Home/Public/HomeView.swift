import Favourites
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import SwiftUI

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
                        nodeUseCase: dependency.nodeUseCase
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
                    ))
                }
            }
            ForEach(0..<10, id: \.self) { index in
                RowView()
                    .background((index % 2 == 0 ? Color.red : Color.yellow))

            }
        }
    }

    // Debug only, will remove later
    private struct RowView: View {
        @State var height = 60.0
        @State var expanded = false
        var body: some View {
            Button {

                withAnimation {
                    if expanded { height /= 2 } else { height *= 2 }
                    expanded.toggle()
                }
            } label: {
                Text("Click to \(expanded ? "collapse" : "expand")")
            }
            .frame(height: height)
                .frame(maxWidth: .infinity)
        }
    }
}
