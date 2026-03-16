import MEGAAppSDKRepo
import MEGADomain

enum RecentActionBucketsListErrorEntity: Error {
    case cancellation
}

protocol RecentActionBucketsListUseCaseProtocol: Sendable {
    func recentActionsBuckets() async throws(RecentActionBucketsListErrorEntity) -> [DailyRecentActionBucketGroup]
}

struct RecentActionBucketsListUseCase: RecentActionBucketsListUseCaseProtocol, Sendable {
    private let recentActionBucketRepository: any RecentActionBucketRepositoryProtocol
    private let dailyRecentActionGrouper: any DailyRecentActionBucketGrouping
    private let userAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    
    init() {
        self.init(
            recentActionBucketRepository: RecentActionBucketRepository.newRepo,
            dailyRecentActionGrouper: DailyRecentActionBucketGrouper(),
            userAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo)
        )
    }

    package init(
        recentActionBucketRepository: some RecentActionBucketRepositoryProtocol,
        dailyRecentActionGrouper: some DailyRecentActionBucketGrouping,
        userAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol
    ) {
        self.recentActionBucketRepository = recentActionBucketRepository
        self.dailyRecentActionGrouper = dailyRecentActionGrouper
        self.userAttributeUseCase = userAttributeUseCase
    }

    func recentActionsBuckets() async throws(RecentActionBucketsListErrorEntity) -> [DailyRecentActionBucketGroup] {
        do {
            let buckets = try await recentActionBucketRepository.getRecentActionBuckets(
                excludeSensitives: !userAttributeUseCase.shouldShowHiddenNodes
            )
            return dailyRecentActionGrouper.group(buckets: buckets)
        } catch is CancellationError {
            throw .cancellation
        } catch {
            MEGALogError("[RecentsWidget] Failed to fetch recent nodes: \(error)")
            return []
        }
    }
}
