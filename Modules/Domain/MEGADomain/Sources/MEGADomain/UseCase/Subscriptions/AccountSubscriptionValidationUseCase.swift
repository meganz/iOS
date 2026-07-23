public protocol AccountSubscriptionValidationUseCaseProtocol: Sendable {
    /// Decides whether a StoreKit plan purchase may proceed for the given account,
    /// and, when it may not, whether the blocking subscription is cancellable in-app.
    func eligibility(for accountDetails: AccountDetailsEntity) -> PlanPurchaseEligibility
}

public struct AccountSubscriptionValidationUseCase: AccountSubscriptionValidationUseCaseProtocol {
    public init() {}

    public func eligibility(for accountDetails: AccountDetailsEntity) -> PlanPurchaseEligibility {
        // No paid, valid, non-Apple subscription in the way → the purchase can go straight to StoreKit.
        guard accountDetails.proLevel != .free,
              accountDetails.subscriptionStatus == .valid,
              accountDetails.subscriptionMethodId != .itunes else {
            return .purchasable
        }

        return switch accountDetails.subscriptionMethodId {
        case .ECP, .sabadell, .stripe2: .hasCancellableSubscription
        default: .hasNonCancellableSubscription
        }
    }
}
