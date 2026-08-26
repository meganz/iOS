import Foundation
import MEGADomain

/// The timing half of a promotional offer's expiry: whether the deadline has lapsed, and
/// suspending until it does. For surfaces, like the promo landing dialog, that react to the
/// lapse itself and carry no post-expiry data.
@MainActor
public protocol PromoExpiryTiming: AnyObject {
    /// `true` when the promotion has already lapsed.
    var hasAlreadyExpired: Bool { get }
    /// Suspends until the promotion lapses. Returns `false` if the surrounding task is cancelled first.
    func waitUntilExpired() async -> Bool
}

/// Builds the monitor that drives the promo-to-standard flip. Injected so tests can substitute a
/// factory whose monitor resolves deterministically instead of sleeping until a deadline.
public protocol PromoExpiryMonitorFactory: Sendable {
    @MainActor func makeMonitor(deadline: Date, accountDetails: AccountDetailsEntity, plans: [PlanEntity]) -> any PromoExpiryMonitoring
}

/// Timing and data behind flipping the revamp Upgrade screen to `.standard` once its featured
/// promotional offer lapses. `AnyObject` so the container can compare monitor identity across a reload.
@MainActor
public protocol PromoExpiryMonitoring: PromoExpiryTiming {
    /// The account details carried into the post-expiry standard page.
    var accountDetails: AccountDetailsEntity { get }
    /// The plans for the post-expiry standard page, with the lapsed offers stripped.
    var plansAfterExpiry: [PlanEntity] { get }
}

/// The one implementation that sleeps out a promotional deadline; every expiry surface shares it.
public final class PromoExpiryTimer: PromoExpiryTiming {
    private let deadline: Date

    /// `nonisolated` so callers that are not on the main actor can still build one; the deadline is
    /// immutable, so there is no isolated state to protect at init time.
    public nonisolated init(deadline: Date) {
        self.deadline = deadline
    }

    /// `true` when the promotion has already lapsed.
    public var hasAlreadyExpired: Bool {
        deadline <= Date()
    }

    /// Suspends until the promotion lapses. Returns `false` if the surrounding task is cancelled
    /// first (e.g. the screen went away or reloaded).
    public func waitUntilExpired() async -> Bool {
        let interval = deadline.timeIntervalSinceNow
        if interval > 0 {
            try? await Task.sleep(for: .seconds(interval))
        }
        return !Task.isCancelled
    }
}

/// Encapsulates the "a featured promotional offer will lapse" concern for the revamp Upgrade
/// screen: the expiry context, suspending until it lapses, and the offer-stripped plans shown
/// afterwards. The container view model owns the resulting state transition; this only supplies
/// the timing and the data.
final class PromoExpiryMonitor: PromoExpiryMonitoring {
    private let timer: PromoExpiryTimer
    let accountDetails: AccountDetailsEntity
    private let plans: [PlanEntity]

    init(deadline: Date, accountDetails: AccountDetailsEntity, plans: [PlanEntity]) {
        self.timer = PromoExpiryTimer(deadline: deadline)
        self.accountDetails = accountDetails
        self.plans = plans
    }

    var hasAlreadyExpired: Bool {
        timer.hasAlreadyExpired
    }

    func waitUntilExpired() async -> Bool {
        await timer.waitUntilExpired()
    }

    /// The plans for the post-expiry standard page, with the lapsed offers stripped so no stale
    /// discount ribbon or discounted price survives the switch.
    var plansAfterExpiry: [PlanEntity] {
        /// Per backend contract, API will all have same expiration date, so after expiration it's guaranteed
        /// that all promotional offers are no longer valid and are safe to be stripped out.
        plans.map { $0.removingPromotionalOffer() }
    }
}

/// The production factory: builds a real `PromoExpiryMonitor`.
public struct DefaultPromoExpiryMonitorFactory: PromoExpiryMonitorFactory {
    public init() {}

    public func makeMonitor(deadline: Date, accountDetails: AccountDetailsEntity, plans: [PlanEntity]) -> any PromoExpiryMonitoring {
        PromoExpiryMonitor(deadline: deadline, accountDetails: accountDetails, plans: plans)
    }
}
