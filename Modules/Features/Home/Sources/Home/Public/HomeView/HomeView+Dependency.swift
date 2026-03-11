import Combine
import Favourites
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import Search
import SwiftUI

extension HomeView {
    public struct Dependency {
        let homeAddMenuActionHandler: any HomeAddMenuActionHandling
        let router: any HomeViewRouting
        let fullNameHandler: @Sendable (CurrentUserSource) -> String
        let avatarFetcher: @Sendable () async -> Image?
        let fileSearchUseCase: any FilesSearchUseCaseProtocol
        let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
        let favouritesSearchResultsMapper: any FavouritesSearchResultsMapping
        let downloadedNodesListener: any DownloadedNodesListening
        let nodeUseCase: any NodeUseCaseProtocol
        let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
        let favouritesNodesActionHandler: any NodesActionHandling
        let onFavouritesEditingChanged: @MainActor (Bool) -> Void
        let favouritesNodeSelectionAction: @MainActor (HandleEntity, [HandleEntity]) -> Void
        let onFavouritesNodeActionPerformed: AnyPublisher<Void, Never>
        // Search result dependencies
        let searchResultsProvider: any SearchResultsProviding
        let searchResultsSelectionHandler: @MainActor (SearchResultSelection) -> Void
        let searchResultNodeActionHandler: @MainActor (NodeAction) -> Void

        public init(
            homeAddMenuActionHandler: some HomeAddMenuActionHandling,
            router: some HomeViewRouting,
            fullNameHandler: @escaping @Sendable (CurrentUserSource) -> String,
            avatarFetcher: @escaping @Sendable () async -> Image?,
            fileSearchUseCase: some FilesSearchUseCaseProtocol,
            sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
            favouritesSearchResultsMapper: some FavouritesSearchResultsMapping,
            downloadedNodesListener: some DownloadedNodesListening,
            nodeUseCase: some NodeUseCaseProtocol,
            sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
            favouritesNodesActionHandler: some NodesActionHandling,
            onFavouritesEditingChanged: @escaping @MainActor (Bool) -> Void,
            favouritesNodeSelectionAction: @escaping @MainActor (HandleEntity, [HandleEntity]) -> Void,
            onFavouritesNodeActionPerformed: AnyPublisher<Void, Never>,
            searchResultsProvider: some SearchResultsProviding,
            searchResultsSelectionHandler: @escaping @MainActor (SearchResultSelection) -> Void,
            searchResultNodeActionHandler: @escaping @MainActor (NodeAction) -> Void
        ) {
            self.homeAddMenuActionHandler = homeAddMenuActionHandler
            self.router = router
            self.fileSearchUseCase = fileSearchUseCase
            self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
            self.favouritesSearchResultsMapper = favouritesSearchResultsMapper
            self.downloadedNodesListener = downloadedNodesListener
            self.nodeUseCase = nodeUseCase
            self.fullNameHandler = fullNameHandler
            self.avatarFetcher = avatarFetcher
            self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
            self.favouritesNodesActionHandler = favouritesNodesActionHandler
            self.onFavouritesEditingChanged = onFavouritesEditingChanged
            self.favouritesNodeSelectionAction = favouritesNodeSelectionAction
            self.onFavouritesNodeActionPerformed = onFavouritesNodeActionPerformed
            self.searchResultsProvider = searchResultsProvider
            self.searchResultsSelectionHandler = searchResultsSelectionHandler
            self.searchResultNodeActionHandler = searchResultNodeActionHandler
        }
    }
}
