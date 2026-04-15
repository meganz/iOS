import Combine
import ContentLibraries
import Favourites
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwiftUI
import Search
import SwiftUI
import Transfer

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
        let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory
        let avatarFetcher: @Sendable () async -> Image?
        let fileSearchUseCase: any FilesSearchUseCaseProtocol
        let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
        let favouritesSearchResultsMapper: any FavouritesSearchResultsMapping
        let downloadedNodesListener: any DownloadedNodesListening
        let nodeUseCase: any NodeUseCaseProtocol
        let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
        let favouritesNodesActionHandler: any NodesActionHandling
        let favouritesMoreActionsPresenter: any MoreNodeActionsPresenting
        let favouritesSelectActionPublisher: AnyPublisher<HandleEntity, Never>
        let userNameProvider: any UserNameProviderProtocol
        let recentActionBucketItemResultMapper: any RecentActionBucketItemResultMapping
        let favouritesNodeSelectionAction: any NodeSelectionHandling
        // Search result dependencies
        let searchResultsProvider: any SearchResultsProviding
        let searchResultsSelectionHandler: any NodeSelectionHandling
        let searchResultNodeActionHandler: any NodesActionHandling
        // No internet state
        let offlineFilesUseCase: any OfflineFilesUseCaseProtocol
        // recent action bucket
        let recentActionBucketNodeSelectionHandler: any NodeSelectionHandling
        let recentActionBucketNodesActionHandler: any NodesActionHandling
        let recentActionBucketMoreActionsPresenter: any MoreNodeActionsPresenting
        let photoLibraryContentViewRouter: any PhotoLibraryContentViewRouting
        let tracker: any AnalyticsTracking

        public init(
            homeAddMenuActionHandler: some HomeAddMenuActionHandling,
            router: some HomeViewRouting,
            transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory,
            avatarFetcher: @escaping @Sendable () async -> Image?,
            fileSearchUseCase: some FilesSearchUseCaseProtocol,
            sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
            favouritesSearchResultsMapper: some FavouritesSearchResultsMapping,
            downloadedNodesListener: some DownloadedNodesListening,
            nodeUseCase: some NodeUseCaseProtocol,
            sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
            favouritesNodesActionHandler: some NodesActionHandling,
            favouritesMoreActionsPresenter: some MoreNodeActionsPresenting,
            favouritesSelectActionPublisher: AnyPublisher<HandleEntity, Never>,
            userNameProvider: some UserNameProviderProtocol,
            recentActionBucketItemResultMapper: some RecentActionBucketItemResultMapping,
            favouritesNodeSelectionAction: some NodeSelectionHandling,
            searchResultsProvider: some SearchResultsProviding,
            offlineFilesUseCase: some OfflineFilesUseCaseProtocol,
            searchResultsSelectionHandler: some NodeSelectionHandling,
            searchResultNodeActionHandler: some NodesActionHandling,
            recentActionBucketNodeSelectionHandler: some NodeSelectionHandling,
            recentActionBucketNodesActionHandler: some NodesActionHandling,
            recentActionBucketMoreActionsPresenter: some MoreNodeActionsPresenting,
            photoLibraryContentViewRouter: some PhotoLibraryContentViewRouting,
            tracker: some AnalyticsTracking
        ) {
            self.homeAddMenuActionHandler = homeAddMenuActionHandler
            self.router = router
            self.transferIndicatorToolbarFactory = transferIndicatorToolbarFactory
            self.fileSearchUseCase = fileSearchUseCase
            self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
            self.favouritesSearchResultsMapper = favouritesSearchResultsMapper
            self.downloadedNodesListener = downloadedNodesListener
            self.nodeUseCase = nodeUseCase
            self.avatarFetcher = avatarFetcher
            self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
            self.favouritesNodesActionHandler = favouritesNodesActionHandler
            self.favouritesMoreActionsPresenter = favouritesMoreActionsPresenter
            self.favouritesSelectActionPublisher = favouritesSelectActionPublisher
            self.userNameProvider = userNameProvider
            self.recentActionBucketItemResultMapper = recentActionBucketItemResultMapper
            self.favouritesNodeSelectionAction = favouritesNodeSelectionAction
            self.searchResultsProvider = searchResultsProvider
            self.searchResultsSelectionHandler = searchResultsSelectionHandler
            self.searchResultNodeActionHandler = searchResultNodeActionHandler
            self.offlineFilesUseCase = offlineFilesUseCase
            self.recentActionBucketNodeSelectionHandler = recentActionBucketNodeSelectionHandler
            self.recentActionBucketNodesActionHandler = recentActionBucketNodesActionHandler
            self.recentActionBucketMoreActionsPresenter = recentActionBucketMoreActionsPresenter
            self.photoLibraryContentViewRouter = photoLibraryContentViewRouter
            self.tracker = tracker
        }
    }
}
