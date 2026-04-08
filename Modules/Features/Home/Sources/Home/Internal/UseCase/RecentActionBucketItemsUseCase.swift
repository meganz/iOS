import MEGAAppSDKRepo
import MEGADomain

protocol RecentActionBucketItemsUseCaseProtocol: Sendable {
    /// Fetch the content of a specific bucket by its ID
    /// - Parameter id: The bucket ID to monitor.
    func fetchBucketContent(forId id: String) async -> RecentActionBucketEntity?
}

struct RecentActionBucketItemsUseCase: RecentActionBucketItemsUseCaseProtocol {
    private let recentActionBucketRepository: any RecentActionBucketRepositoryProtocol
    private let userAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol

    init() {
        self.init(
            recentActionBucketRepository: RecentActionBucketRepository.newRepo,
            userAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo)
        )
    }

    package init(
        recentActionBucketRepository: some RecentActionBucketRepositoryProtocol,
        userAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol
    ) {
        self.recentActionBucketRepository = recentActionBucketRepository
        self.userAttributeUseCase = userAttributeUseCase
    }

    func fetchBucketContent(forId id: String) async -> RecentActionBucketEntity? {
        try? await recentActionBucketRepository.getRecentActionBucket(byId: id, excludeSensitives: !userAttributeUseCase.shouldShowHiddenNodes)
    }
}
