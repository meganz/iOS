import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift
import Search

final class RecentActionBucketProvider: SearchResultsProviding, @unchecked Sendable {
    
    // here we check if given node update is a important for currently shown bucket,
    // this is taken from `func shouldProcessOnNodesUpdate` in `CloudDriveViewController+NodesUpdate`
    func shouldProcessOnNodesUpdate(
        updatedNodes: [NodeEntity]
    ) -> Bool {
        guard let parentNodeEntity = bucket.parentNode() else { return false }
        return nodeUpdateRepository
            .shouldProcessOnNodesUpdate(
                parentNode: parentNodeEntity,
                childNodes: bucket.allNodes(),
                updatedNodes: updatedNodes
            )
    }
    
    // Adopted from `reloadRecentActionBucketAfterNodeUpdates` in CloudDriveViewController+NodesUpdate.
    // We could not use `RecentNodesRepository`, as we still need SDK's `MEGARecentActionBucket` until
    // we are supporting legacy code.
    // Namely there's no way to go RecentActionBucketEntity to MEGARecentActionBucket object
    // A sequence that re-reads a current state of current bucket out of the recent buckets stored in SDK
    private func refetchedBucket(excludeSensitive: Bool) -> AnyAsyncSequence<any RecentActionBucket> {
        
        let currentBucketNodeHandles: Set<HandleEntity> = Set(bucket.allNodes().map { $0.handle })
        
        return AsyncStream<any RecentActionBucket> { continuation in
            
            // This follows the logic of `RecentsViewController.getRecentActions`
            sdk.getRecentActionsAsync(
                sinceDays: 30,
                maxNodes: 500,
                excludeSensitives: excludeSensitive,
                delegate: RequestDelegate { result in
                    guard case let .success(request) = result else {
                        continuation.finish()
                        return
                    }
                    
                    guard let recentBuckets = request.recentActionsBuckets else {
                        continuation.finish()
                        return
                    }
                    
                    let updatedBucket: MEGARecentActionBucket? = recentBuckets.first { bucket in
                        guard bucket.parentHandle == bucket.parentHandle else { return false }
                        
                        // There can be different buckets with the same parentHandle.
                        // In order to correctly get the matching bucket, we need to check if the new bucket has
                        // common nodes with the current bucket
                        let bucketNodeHandles = Set((bucket.nodesList?.toNodeEntities() ?? []).map(\.handle))
                        
                        return !currentBucketNodeHandles.isDisjoint(with: bucketNodeHandles)
                    }
                    
                    // this means, bucket was emptied, we will show empty screen.
                    // Legacy CD did dismiss in this scenario
                    // Quote from legacy CD:
                    // """
                    //     There's no matching bucket (e.g: All the files in the current buckets are deleted).
                    //     Ideally we should display empty list, but there's no API to remove all the nodes of a
                    //    `nodesList`. So I dismiss the screen as a temporary solution
                    // """
                    guard let updatedBucket else {
                        continuation.yield(MEGARecentActionBucketTrampoline.empty)
                        continuation.finish()
                        return
                    }
                    
                    let bucketTrampoline = MEGARecentActionBucketTrampoline(
                        bucket: updatedBucket,
                        parentNodeProvider: {[weak self] parentHandle in
                            guard let self else { return nil }
                            return sdk.node(forHandle: parentHandle)?.toNodeEntity()
                        }
                    )
                    continuation.yield(bucketTrampoline)
                    continuation.finish()
                    
                })
        }
        .eraseToAnyAsyncSequence()
    }
    
    private var excludeSensitivesStream: AnyAsyncSequence<Bool> {
        AsyncStream { continuation in
            Task {
                let value = await self.sensitiveDisplayPreferenceUseCase.excludeSensitives()
                continuation.yield(value)
                continuation.finish()
            }
        }.eraseToAnyAsyncSequence()
    }
    
    // here we are listening to changes interesting to us and
    // emit an updated bucket if it was changed
    private func refreshedBucket() -> AnyAsyncSequence<any RecentActionBucket> {
        nodeUseCase.nodeUpdates
            .filter { [weak self] updatedNodes -> Bool in
                guard let self else { return false }
                return self.shouldProcessOnNodesUpdate(
                    updatedNodes: updatedNodes
                )
            }
            .flatMap { _ in
                self.excludeSensitivesStream
            }
            .flatMap { [weak self] excludeSensitives in
                if let bucket = self?.refetchedBucket(excludeSensitive: excludeSensitives) {
                    return bucket
                } else {
                    return EmptyAsyncSequence<any RecentActionBucket>().eraseToAnyAsyncSequence()
                }
            }
            .eraseToAnyAsyncSequence()
    }
    
    // DISCLAIMER: ONLY ONE SUBSCRIBER
    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        let (stream, continuation) = AsyncStream.makeStream(of: SearchResultUpdateSignal.self, bufferingPolicy: .bufferingNewest(1))
        self.$continuation.mutate {
            $0 = continuation
        }
        return stream.eraseToAnyAsyncSequence()
    }
    
    func refreshedSearchResults(queryRequest: SearchQuery) async throws -> SearchResultsEntity? {
        // no paging in recent action buckets
        await search(queryRequest: queryRequest, lastItemIndex: nil)
    }
    
    func currentResultIds() -> [Search.ResultId] {
        bucket.allNodes().map(\.handle)
    }
    
    @Atomic private var bucket: any RecentActionBucket
    @Atomic private var continuation: AsyncStream<SearchResultUpdateSignal>.Continuation?
    private var mapper: SearchResultMapper
    private var nodeUseCase: any NodeUseCaseProtocol
    private var changedNodesTask: Task<Void, Never>?
    private let nodeUpdateRepository: any NodeUpdateRepositoryProtocol
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let sdk: MEGASdk
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    init(
        // we will be able to remove the sdk dependency when legacy cloud drive code is deleted
        // it's because we need ability to get MEGARecentActionBBucket from RecentActionBucketEntity
        sdk: MEGASdk,
        bucket: some RecentActionBucket,
        mapper: SearchResultMapper,
        nodeUseCase: some NodeUseCaseProtocol,
        nodeUpdateRepository: some NodeUpdateRepositoryProtocol,
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.sdk = sdk
        self._bucket = .init(wrappedValue: bucket)
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.mapper = mapper
        self.nodeUseCase = nodeUseCase
        self.nodeUpdateRepository = nodeUpdateRepository
        self.featureFlagProvider = featureFlagProvider

        let sequence = refreshedBucket()
        changedNodesTask = Task { [weak self] in
            guard let self else { return }
            for await refreshedBucket in sequence {
                guard !Task.isCancelled else { break }
                // here we update the local state holding source of truth
                $bucket.mutate { bucket in
                    bucket = refreshedBucket
                }
                // and then inform view layer that we had a change so
                // results should be refreshed
                continuation?.yield(.generic)
            }
        }
    }
    
    deinit {
        changedNodesTask?.cancel()
    }
    
    func search(
        queryRequest: SearchQuery,
        lastItemIndex: Int?
    ) async -> SearchResultsEntity? {
        switch queryRequest {
        case .initial:
            if lastItemIndex != nil {
                return .empty
            } else {
                return all
            }
        case .userSupplied(let queryEntity):
            let filtered = filtered(queryEntity)
            if lastItemIndex != nil {
                return .empty
            } else {
                return filtered
            }
        }
    }
    
    func allBucketResults(queryEntity: SearchQueryEntity? = nil) -> [SearchResult] {
        nodeEntities(queryEntity).map(mapper.map(node:))
    }
    
    func nodeEntities(_ queryEntity: SearchQueryEntity? = nil) -> [NodeEntity] {
        let list = bucket.allNodes()
        guard let queryEntity, queryEntity.query.isNotEmpty else {
            return list // return all when no query
        }

        let textQuery = queryEntity.query
        let tagQuery = textQuery.removingFirstLeadingHash()
        return list.filter { item in
            return (item.name.containsIgnoringCaseAndDiacritics(searchText: textQuery)
                    || item.description?.containsIgnoringCaseAndDiacritics(searchText: textQuery) == true
                    || item.tags.contains(where: { $0.containsIgnoringCaseAndDiacritics(searchText: tagQuery) })
            )
        }
    }

    var all: SearchResultsEntity {
        .init(
            results: allBucketResults(queryEntity: nil),
            availableChips: [],
            appliedChips: []
        )
    }
    
    func filtered(_ queryEntity: SearchQueryEntity) -> SearchResultsEntity {
        .init(
            results: allBucketResults(queryEntity: queryEntity),
            availableChips: [],
            appliedChips: []
        )
    }
}
