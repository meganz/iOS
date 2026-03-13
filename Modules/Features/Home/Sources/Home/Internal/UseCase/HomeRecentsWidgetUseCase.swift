import MEGAAppSDKRepo
import MEGADomain

enum HomeRecentWidgetsErrorEntity: Error {
    case cancellation
}

protocol HomeRecentsWidgetUseCaseProtocol: Sendable {
    func recentBuckets() async throws(HomeRecentWidgetsErrorEntity) -> [DailyRecentActionBucketGroup]
}

struct HomeRecentsWidgetUseCase: HomeRecentsWidgetUseCaseProtocol, Sendable {
    private let maxShowingBuckets = 4
    private let recentActionBucketRepository: any RecentActionBucketRepositoryProtocol
    private let dailyRecentActionGrouper: any DailyRecentActionBucketGrouping
    
    init() {
        self.init(
            recentActionBucketRepository: RecentActionBucketRepository.newRepo,
            dailyRecentActionGrouper: DailyRecentActionBucketGrouper()
        )
    }

    package init(
        recentActionBucketRepository: some RecentActionBucketRepositoryProtocol,
        dailyRecentActionGrouper: some DailyRecentActionBucketGrouping
    ) {
        self.recentActionBucketRepository = recentActionBucketRepository
        self.dailyRecentActionGrouper = dailyRecentActionGrouper
    }

    func recentBuckets() async throws(HomeRecentWidgetsErrorEntity) -> [DailyRecentActionBucketGroup] {
        do {
            let buckets = try await recentActionBucketRepository.getRecentActionBuckets()
            let recentWidgetsBucket = Array(buckets.prefix(maxShowingBuckets))
            return dailyRecentActionGrouper.group(buckets: recentWidgetsBucket)
        } catch is CancellationError {
            throw .cancellation
        } catch {
            MEGALogError("[RecentsWidget] Failed to fetch recent nodes: \(error)")
            return []
        }
    }
}
