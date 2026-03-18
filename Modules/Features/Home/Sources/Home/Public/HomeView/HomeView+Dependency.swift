import Combine
import Favourites
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import Search
import SwiftUI

/// @MainActor is required as its conformer would be MEGAStore from main target
@MainActor
public protocol UserNameProviderProtocol: Sendable {
    func displayName(for user: UserEntity) -> String?
}

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
        let userNameProvider: any UserNameProviderProtocol
        let onFavouritesEditingChanged: @MainActor (Bool) -> Void
        let favouritesNodeSelectionAction: @MainActor (HandleEntity, [HandleEntity]) -> Void
        let onFavouritesNodeActionPerformed: AnyPublisher<Void, Never>
        // Search result dependencies
        let searchResultsProvider: any SearchResultsProviding
        let searchResultsSelectionHandler: @MainActor (SearchResultSelection) -> Void
        let searchResultNodeActionHandler: @MainActor (NodeAction) -> Void

        // No internet state
        let offlineFilesUseCase: any OfflineFilesUseCaseProtocol

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
            userNameProvider: some UserNameProviderProtocol,
            onFavouritesEditingChanged: @escaping @MainActor (Bool) -> Void,
            favouritesNodeSelectionAction: @escaping @MainActor (HandleEntity, [HandleEntity]) -> Void,
            onFavouritesNodeActionPerformed: AnyPublisher<Void, Never>,
            searchResultsProvider: some SearchResultsProviding,
            searchResultsSelectionHandler: @escaping @MainActor (SearchResultSelection) -> Void,
            searchResultNodeActionHandler: @escaping @MainActor (NodeAction) -> Void,
            offlineFilesUseCase: some OfflineFilesUseCaseProtocol,
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
            self.userNameProvider = userNameProvider
            self.onFavouritesEditingChanged = onFavouritesEditingChanged
            self.favouritesNodeSelectionAction = favouritesNodeSelectionAction
            self.onFavouritesNodeActionPerformed = onFavouritesNodeActionPerformed
            self.searchResultsProvider = searchResultsProvider
            self.searchResultsSelectionHandler = searchResultsSelectionHandler
            self.searchResultNodeActionHandler = searchResultNodeActionHandler
            self.offlineFilesUseCase = offlineFilesUseCase
        }
    }
}
