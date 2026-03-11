import MEGAAppSDKRepo
import MEGADomain

protocol HomeRecentsWidgetUseCaseProtocol: Sendable {
    func recentBuckets() async -> [RecentActionBucketEntity]?
}

struct HomeRecentsWidgetUseCase: HomeRecentsWidgetUseCaseProtocol, Sendable {
    private enum Constants {
        static let recentActionBucketsLimit = 1
    }

    private let recentNodesUseCase: any RecentNodesUseCaseProtocol

    init() {
        self.init(
            recentNodesUseCase: RecentNodesUseCase(
                recentNodesRepository: RecentNodesRepository.newRepo,
                contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
                userUpdateRepository: UserUpdateRepository.newRepo,
                requestStatesRepository: RequestStatesRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            )
        )
    }

    package init(recentNodesUseCase: some RecentNodesUseCaseProtocol) {
        self.recentNodesUseCase = recentNodesUseCase
    }

    func recentBuckets() async -> [RecentActionBucketEntity]? {
        do {
            return try await recentNodesUseCase.recentActionBuckets(limitCount: Constants.recentActionBucketsLimit)
        } catch is CancellationError {
            return nil
        } catch {
            MEGALogError("[RecentsWidget] Failed to fetch recent nodes: \(error)")
            return []
        }
    }
}
