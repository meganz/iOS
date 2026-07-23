/// Whether an account may start a StoreKit plan purchase,
/// and, when it may not, whether the blocking subscription can be cancelled in-app before buying.
///
/// Encodes the business rule the legacy subscription screen expressed via a thrown
/// `ActiveSubscriptionError`; here it is a pure, exhaustively switchable outcome,
///  so consumers (e.g: the revamp quota dialog and the revamp subscription page) can steer their UI without control-flow-by-exception.
public enum PlanPurchaseEligibility: Sendable, Equatable {
    /// No active non-iTunes subscription stands in the way, hence the purchase can proceed.
    case purchasable
    /// An active web subscription (credit-card: ECP / Sabadell / Stripe) can be cancelled in-app,
    /// then the new plan purchased.
    case hasCancellableSubscription
    /// An active non-iTunes subscription that cannot be cancelled in-app, the user must be informed.
    case hasNonCancellableSubscription
}
