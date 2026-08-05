import MEGAAppSDKRepo
import MEGADomain

/// Decides whether a plan purchase may start, and clears an in-app-cancellable subscription out of the way.
///
/// Purchasers depend on this rather than the concrete ``PlanPurchaseEligibilityChecker`` so a test can script
/// the decision without standing up three use cases.
@MainActor
public protocol PlanPurchaseEligibilityChecking {
    /// Reads the cached account details, so it never waits on the network.
    func eligibility() -> PlanPurchaseEligibility
    /// Cancels the active subscription.
    /// - Returns: `false` when the cancellation request failed.
    func cancelActiveSubscription() async -> Bool
    /// Re-reads the account from the API, for confirming a cancellation actually cleared the way.
    func refreshedEligibility() async -> PlanPurchaseEligibility
}

/// Decides whether a plan purchase may start, and clears an in-app-cancellable subscription out of the way.
///
/// Shared by ``PlanPurchaser`` and ``ExternalPlanPurchaser`` so the in-app and website routes apply one rule.
/// It answers the question and performs the cancellation; deciding what to do next belongs to the caller,
/// which is what lets each purchaser resume its own route after the user confirms.
@MainActor
public struct PlanPurchaseEligibilityChecker: PlanPurchaseEligibilityChecking {
    private let subscriptionsUseCase: any SubscriptionsUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let validationUseCase: any AccountSubscriptionValidationUseCaseProtocol

    public init(
        subscriptionsUseCase: some SubscriptionsUseCaseProtocol = SubscriptionsUseCase(repo: SubscriptionsRepository.newRepo),
        accountUseCase: some AccountUseCaseProtocol = AccountUseCase(repository: AccountRepository.newRepo),
        validationUseCase: some AccountSubscriptionValidationUseCaseProtocol = AccountSubscriptionValidationUseCase()
    ) {
        self.subscriptionsUseCase = subscriptionsUseCase
        self.accountUseCase = accountUseCase
        self.validationUseCase = validationUseCase
    }

    public func eligibility() -> PlanPurchaseEligibility {
        eligibility(for: accountUseCase.currentAccountDetails)
    }

    public func cancelActiveSubscription() async -> Bool {
        do {
            try await subscriptionsUseCase.cancelSubscriptions()
            return true
        } catch {
            return false
        }
    }

    public func refreshedEligibility() async -> PlanPurchaseEligibility {
        eligibility(for: try? await accountUseCase.refreshCurrentAccountDetails())
    }

    /// Missing details cannot block a purchase, so they are treated as purchasable.
    private func eligibility(for details: AccountDetailsEntity?) -> PlanPurchaseEligibility {
        guard let details else { return .purchasable }
        return validationUseCase.eligibility(for: details)
    }
}
