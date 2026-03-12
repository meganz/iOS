import MEGAAppSDKRepo
import MEGADomain

protocol HomeRecentsWidgetUseCaseProtocol: Sendable {
    func recentBuckets() async -> [RecentActionBucketEntity]?
}

struct HomeRecentsWidgetUseCase: HomeRecentsWidgetUseCaseProtocol, Sendable {
    private let maxShowingBuckets = 4
    private let recentActionBucketRepository: any RecentActionBucketRepositoryProtocol

    init() {
        self.init(recentActionBucketRepository: RecentActionBucketRepository.newRepo)
    }

    package init(recentActionBucketRepository: some RecentActionBucketRepositoryProtocol) {
        self.recentActionBucketRepository = recentActionBucketRepository
    }

    func recentBuckets() async -> [RecentActionBucketEntity]? {
        do {
            let buckets = try await recentActionBucketRepository.getRecentActionBuckets()
            return Array(buckets.prefix(maxShowingBuckets))
        } catch is CancellationError {
            return nil
        } catch {
            MEGALogError("[RecentsWidget] Failed to fetch recent nodes: \(error)")
            return []
        }
    }
}
