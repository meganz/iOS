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

public protocol RecentActionBucketItemResultMapping: Sendable {
    func map(node: NodeEntity) -> SearchResult
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
        let recentActionBucketItemResultMapper: any RecentActionBucketItemResultMapping
        let onFavouritesEditingChanged: @MainActor (Bool) -> Void
        let favouritesNodeSelectionAction: any NodeSelectionHandling
        let onFavouritesNodeActionPerformed: AnyPublisher<Void, Never>
        // Search result dependencies
        let searchResultsProvider: any SearchResultsProviding
        let searchResultsSelectionHandler: any NodeSelectionHandling
        let searchResultNodeActionHandler: any NodesActionHandling
        // No internet state
        let offlineFilesUseCase: any OfflineFilesUseCaseProtocol
        // recent action bucket
        let recentActionBucketNodeSelectionHandler: any NodeSelectionHandling
        let recentActionBucketNodesActionHandler: any NodesActionHandling
        
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
            recentActionBucketItemResultMapper: some RecentActionBucketItemResultMapping,
            onFavouritesEditingChanged: @escaping @MainActor (Bool) -> Void,
            favouritesNodeSelectionAction: some NodeSelectionHandling,
            onFavouritesNodeActionPerformed: AnyPublisher<Void, Never>,
            searchResultsProvider: some SearchResultsProviding,
            offlineFilesUseCase: some OfflineFilesUseCaseProtocol,
            searchResultsSelectionHandler: some NodeSelectionHandling,
            searchResultNodeActionHandler: some NodesActionHandling,
            recentActionBucketNodeSelectionHandler: some NodeSelectionHandling,
            recentActionBucketNodesActionHandler: some NodesActionHandling
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
            self.recentActionBucketItemResultMapper = recentActionBucketItemResultMapper
            self.onFavouritesEditingChanged = onFavouritesEditingChanged
            self.favouritesNodeSelectionAction = favouritesNodeSelectionAction
            self.onFavouritesNodeActionPerformed = onFavouritesNodeActionPerformed
            self.searchResultsProvider = searchResultsProvider
            self.searchResultsSelectionHandler = searchResultsSelectionHandler
            self.searchResultNodeActionHandler = searchResultNodeActionHandler
            self.offlineFilesUseCase = offlineFilesUseCase
            self.recentActionBucketNodeSelectionHandler = recentActionBucketNodeSelectionHandler
            self.recentActionBucketNodesActionHandler = recentActionBucketNodesActionHandler
        }
    }
}
