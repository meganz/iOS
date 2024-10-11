public protocol SubscriptionsUseCaseProtocol: Sendable {
    /// Cancels credit card subscriptions with optional parameters for providing a reason, subscription ID, and contact preference.
    ///
    /// - Default Values:
    ///   - `reason`: `nil` (No reason is specified).
    ///   - `subscriptionId`: `nil` (All active web subscriptions will be cancelled if no specific ID is provided).
    ///   - `canContact`: `false` (The user will not be contacted, consistent with the value assigned in the old function to cancel subscriptions).
    ///
    /// - Throws: An error if the cancellation fails.
    ///
    func cancelSubscriptions(reason: String?, subscriptionId: String?, canContact: Bool) async throws
}

public extension SubscriptionsUseCaseProtocol {
    /// Cancels all active web credit card subscriptions without providing a reason or contact preference.
    func cancelSubscriptions() async throws {
        try await cancelSubscriptions(
            reason: nil,
            subscriptionId: nil,
            canContact: false
        )
    }
    
    /// Cancels all active web credit card subscriptions with a specified reason.
    func cancelSubscriptions(reason: String) async throws {
        try await cancelSubscriptions(
            reason: reason,
            subscriptionId: nil,
            canContact: false
        )
    }
    
    /// Cancels a specific credit card subscription with a reason and a subscription ID.
    func cancelSubscriptions(
        reason: String,
        subscriptionId: String
    ) async throws {
        try await cancelSubscriptions(
            reason: reason,
            subscriptionId: subscriptionId,
            canContact: false
        )
    }
}

public struct SubscriptionsUseCase: SubscriptionsUseCaseProtocol, Sendable {
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
