import Foundation
import MEGADomain

/// Builds the monitor that drives the promo-to-standard flip. Injected so tests can substitute a
/// factory whose monitor resolves deterministically instead of sleeping until a deadline.
public protocol PromoExpiryMonitorFactory: Sendable {
    @MainActor func makeMonitor(deadline: Date, accountDetails: AccountDetailsEntity, plans: [PlanEntity]) -> any PromoExpiryMonitoring
}

/// Timing and data behind flipping the revamp Upgrade screen to `.standard` once its featured
/// promotional offer lapses. `AnyObject` so the container can compare monitor identity across a reload.
@MainActor
public protocol PromoExpiryMonitoring: AnyObject {
    /// `true` when the promotion has already lapsed, so the promo page should be skipped entirely.
    var hasAlreadyExpired: Bool { get }
    /// The account details carried into the post-expiry standard page.
    var accountDetails: AccountDetailsEntity { get }
    /// The plans for the post-expiry standard page, with the lapsed offers stripped.
    var plansAfterExpiry: [PlanEntity] { get }
    /// Suspends until the promotion lapses. Returns `false` if the surrounding task is cancelled first.
    func waitUntilExpired() async -> Bool
}

/// Encapsulates the "a featured promotional offer will lapse" concern for the revamp Upgrade
/// screen: the expiry context, suspending until it lapses, and the offer-stripped plans shown
/// afterwards. The container view model owns the resulting state transition; this only supplies
/// the timing and the data.
@MainActor
final class PromoExpiryMonitor: PromoExpiryMonitoring {
    private let deadline: Date
    let accountDetails: AccountDetailsEntity
    private let plans: [PlanEntity]

    init(deadline: Date, accountDetails: AccountDetailsEntity, plans: [PlanEntity]) {
        self.deadline = deadline
        self.accountDetails = accountDetails
        self.plans = plans
    }

    /// `true` when the promotion has already lapsed, so the promo page should be skipped entirely.
    var hasAlreadyExpired: Bool {
        deadline <= Date()
    }

    /// Suspends until the promotion lapses. Returns `false` if the surrounding task is cancelled
    /// first (e.g. the screen went away or reloaded).
    func waitUntilExpired() async -> Bool {
        let interval = deadline.timeIntervalSinceNow
        if interval > 0 {
            try? await Task.sleep(for: .seconds(interval))
        }
        return !Task.isCancelled
    }

    /// The plans for the post-expiry standard page, with the lapsed offers stripped so no stale
    /// discount ribbon or discounted price survives the switch.
    var plansAfterExpiry: [PlanEntity] {
        plans.map { $0.removingPromotionalOffer() }
    }
}

/// The production factory: builds a real `PromoExpiryMonitor`.
public struct DefaultPromoExpiryMonitorFactory: PromoExpiryMonitorFactory {
    public init() {}

    @MainActor public func makeMonitor(deadline: Date, accountDetails: AccountDetailsEntity, plans: [PlanEntity]) -> any PromoExpiryMonitoring {
        PromoExpiryMonitor(deadline: deadline, accountDetails: accountDetails, plans: plans)
    }
}

package extension PlanEntity {
    func removingPromotionalOffer() -> PlanEntity {
        var plan = self
        plan.promotionalOffer = nil
        plan.mobileOffer = nil
        return plan
    }
}
