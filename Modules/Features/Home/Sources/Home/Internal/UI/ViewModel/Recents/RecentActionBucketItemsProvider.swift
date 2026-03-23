import AsyncAlgorithms
import Combine
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift
import Search

final class RecentActionBucketItemsProvider: SearchResultsProviding {
    private let bucketId: String
    private let recentActionBucketRepository: any RecentActionBucketRepositoryProtocol
    private let resultMapper: any RecentActionBucketItemResultMapping
    private let downloadedNodesListener: any DownloadedNodesListening
    private let recentNodesUseCase: any RecentNodesUseCaseProtocol
    private let currentNodes: Atomic<[NodeEntity]> = Atomic(wrappedValue: [])

    init(
        bucketId: String,
        recentActionBucketRepository: some RecentActionBucketRepositoryProtocol = RecentActionBucketRepository.newRepo,
        resultMapper: any RecentActionBucketItemResultMapping,
        downloadedNodesListener: some DownloadedNodesListening,
        recentNodesUseCase: some RecentNodesUseCaseProtocol = RecentNodesUseCase(
            recentNodesRepository: RecentNodesRepository.newRepo,
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
            userUpdateRepository: UserUpdateRepository.newRepo,
            requestStatesRepository: RequestStatesRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
    ) {
        self.bucketId = bucketId
        self.recentActionBucketRepository = recentActionBucketRepository
        self.resultMapper = resultMapper
        self.downloadedNodesListener = downloadedNodesListener
        self.recentNodesUseCase = recentNodesUseCase
    }

    func refreshedSearchResults(queryRequest: Search.SearchQuery) async throws -> Search.SearchResultsEntity? {
        await search(queryRequest: queryRequest, lastItemIndex: nil)
    }

    func search(queryRequest: Search.SearchQuery, lastItemIndex: Int?) async -> Search.SearchResultsEntity? {
        guard lastItemIndex == nil else {
            return SearchResultsEntity(results: [], availableChips: [], appliedChips: [])
        }

        guard let bucket = try? await recentActionBucketRepository.getRecentActionBucket(byId: bucketId) else { return nil }

        currentNodes.mutate { $0 = bucket.nodes }
        return SearchResultsEntity(
            results: bucket.nodes.map { resultMapper.map(node: $0) },
            availableChips: [],
            appliedChips: []
        )
    }

    func currentResultIds() -> [Search.ResultId] {
        currentNodes.wrappedValue.map(\.handle)
    }

    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        merge(specificNodeUpdateSequence(), genericNodeUpdateSequence())
            .eraseToAnyAsyncSequence()
    }

    // MARK: - Private methods

    private func specificNodeUpdateSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        downloadedNodesListener.downloadedNodes
            .filter { [weak self] in self?.currentResultIds().contains($0.handle) == true }
            .map { [resultMapper] in SearchResultUpdateSignal.specific(result: resultMapper.map(node: $0)) }
            .eraseToAnyAsyncSequence()
    }

    private func genericNodeUpdateSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        recentNodesUseCase
            .recentActionBucketsUpdates
            .map { SearchResultUpdateSignal.generic }
            .eraseToAnyAsyncSequence()
    }
}
