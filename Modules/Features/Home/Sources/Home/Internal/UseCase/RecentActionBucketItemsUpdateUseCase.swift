import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

enum RecentActionBucketUpdatesEntity: Sendable, Equatable {
    case unavailable
    case available(_ bucketEntity: RecentActionBucketEntity)
}

protocol RecentActionBucketItemsUpdateUseCaseProtocol: Sendable {
    /// Yields an updated `RecentActionBucketEntity` each time the bucket with the given ID changes.
    /// - Parameter id: The bucket ID to monitor.
    func bucketUpdates(forId id: String) -> AnyAsyncSequence<RecentActionBucketUpdatesEntity>
}

struct RecentActionBucketItemsUpdateUseCase: RecentActionBucketItemsUpdateUseCaseProtocol {
    private let recentNodesUseCase: any RecentNodesUseCaseProtocol
    private let recentActionBucketRepository: any RecentActionBucketRepositoryProtocol
    private let userAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol

    init() {
        self.init(
            recentNodesUseCase: RecentNodesUseCase(
                recentNodesRepository: RecentNodesRepository.newRepo,
                contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
                userUpdateRepository: UserUpdateRepository.newRepo,
                requestStatesRepository: RequestStatesRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            recentActionBucketRepository: RecentActionBucketRepository.newRepo,
            userAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo)
        )
    }

    package init(
        recentNodesUseCase: some RecentNodesUseCaseProtocol,
        recentActionBucketRepository: some RecentActionBucketRepositoryProtocol,
        userAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol
    ) {
        self.recentNodesUseCase = recentNodesUseCase
        self.recentActionBucketRepository = recentActionBucketRepository
        self.userAttributeUseCase = userAttributeUseCase
    }

    func bucketUpdates(forId id: String) -> AnyAsyncSequence<RecentActionBucketUpdatesEntity> {
        recentNodesUseCase
            .recentActionBucketsUpdates
            .map { [recentActionBucketRepository] in
                return (try? await recentActionBucketRepository.getRecentActionBucket(
                    byId: id,
                    excludeSensitives: !userAttributeUseCase.shouldShowHiddenNodes
                )
                ).map { .available($0) } ?? .unavailable
            }
            .eraseToAnyAsyncSequence()
    }
}
