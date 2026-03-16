protocol ClearRecentActionHistoryUseCaseProtocol: Sendable {
    func clearRecentActionHistory() async throws
}

struct ClearRecentActionHistoryUseCase: ClearRecentActionHistoryUseCaseProtocol, Sendable {

    private let recentActionBucketRepository: any RecentActionBucketRepositoryProtocol

    init() {
        self.init(recentActionBucketRepository: RecentActionBucketRepository.newRepo)
    }

    package init(recentActionBucketRepository: some RecentActionBucketRepositoryProtocol) {
        self.recentActionBucketRepository = recentActionBucketRepository
    }

    func clearRecentActionHistory() async throws {
        try await recentActionBucketRepository.clearRecentActionBuckets(until: .now)
    }
}
