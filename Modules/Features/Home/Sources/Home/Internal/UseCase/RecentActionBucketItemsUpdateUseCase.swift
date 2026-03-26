import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

protocol RecentActionBucketItemsUpdateUseCaseProtocol: Sendable {
    /// Yields an updated `RecentActionBucketEntity` each time the bucket with the given ID changes.
    /// - Parameter id: The bucket ID to monitor.
    func bucketUpdates(forId id: String) -> AnyAsyncSequence<RecentActionBucketEntity>
}

struct RecentActionBucketItemsUpdateUseCase: RecentActionBucketItemsUpdateUseCaseProtocol {
    private let recentNodesUseCase: any RecentNodesUseCaseProtocol
    private let recentActionBucketRepository: any RecentActionBucketRepositoryProtocol

    init() {
        self.init(
            recentNodesUseCase: RecentNodesUseCase(
                recentNodesRepository: RecentNodesRepository.newRepo,
                contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
                userUpdateRepository: UserUpdateRepository.newRepo,
                requestStatesRepository: RequestStatesRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            recentActionBucketRepository: RecentActionBucketRepository.newRepo
        )
    }

    package init(
        recentNodesUseCase: some RecentNodesUseCaseProtocol,
        recentActionBucketRepository: some RecentActionBucketRepositoryProtocol
    ) {
        self.recentNodesUseCase = recentNodesUseCase
        self.recentActionBucketRepository = recentActionBucketRepository
    }

    func bucketUpdates(forId id: String) -> AnyAsyncSequence<RecentActionBucketEntity> {
        recentNodesUseCase
            .recentActionBucketsUpdates
            .compactMap { [recentActionBucketRepository] in
                // error will be handled in IOS-11607
                try? await recentActionBucketRepository.getRecentActionBucket(byId: id)
            }
            .eraseToAnyAsyncSequence()
    }
}
