public protocol SubscriptionsUsecaseProtocol {
    func cancelSubscriptions(reason: String?, subscriptionId: String?, canContact: Bool) async throws
}

public struct SubscriptionsUsecase: SubscriptionsUsecaseProtocol {
    private let repo: any SubscriptionRepositoryProtocol
    
    public init(repo: some SubscriptionRepositoryProtocol) {
        self.repo = repo
    }
    
    public func cancelSubscriptions(reason: String?, subscriptionId: String?, canContact: Bool) async throws {
        try await repo.cancelSubscriptions(
            reason: reason,
            subscriptionId: subscriptionId,
            canContact: canContact
        )
    }
}
