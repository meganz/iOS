import Combine

/// Alert the host presents in reaction to a purchase attempt, whichever route was tried.
public enum PlanPurchaseAlert: Identifiable {
    case failed
    case promotionalOfferUnavailable
    /// A failure on the website route, which has nothing to do with the App Store.
    case websitePurchaseFailed
    case activeCancellableSubscription(confirmCancelAndBuy: @MainActor () async -> Void)
    case activeNonCancellableSubscription

    public var id: String {
        switch self {
        case .failed: "failed"
        case .promotionalOfferUnavailable: "promotionalOfferUnavailable"
        case .websitePurchaseFailed: "websitePurchaseFailed"
        case .activeCancellableSubscription: "activeCancellableSubscription"
        case .activeNonCancellableSubscription: "activeNonCancellableSubscription"
        }
    }
}

/// A view model that can raise a ``PlanPurchaseAlert``, so one alert modifier serves every purchase route.
@MainActor
public protocol PlanPurchaseAlertPresenting: ObservableObject {
    var presentedAlert: PlanPurchaseAlert? { get set }
}
