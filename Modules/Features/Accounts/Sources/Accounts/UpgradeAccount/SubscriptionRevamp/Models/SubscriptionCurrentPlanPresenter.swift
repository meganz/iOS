import Foundation
import MEGADomain
import MEGAL10n

/// Entity -> presentation mapping for the revamp Upgrade page's current-plan
struct SubscriptionCurrentPlanPresenter {
    /// Snapshot of the loaded account state the card is derived from.
    let accountDetails: AccountDetailsEntity
    /// Available plans, used to resolve the current plan's display name.
    let plans: [PlanEntity]
    /// Resolves the display name for an account type not present in `plans`.
    let displayName: @Sendable (AccountTypeEntity) -> String
    /// Reference time used to decide whether the plan is expiring soon.
    let now: Date

    init(
        accountDetails: AccountDetailsEntity,
        plans: [PlanEntity],
        displayName: @escaping @Sendable (AccountTypeEntity) -> String,
        now: Date = Date()
    ) {
        self.accountDetails = accountDetails
        self.plans = plans
        self.displayName = displayName
        self.now = now
    }

    /// The current-plan card model, or `nil` for free accounts (no card shown).
    var currentPlanViewModel: SubscriptionCurrentPlanViewModel? {
        guard let plan = Self.makeCurrentPlan(for: accountDetails, in: plans, displayName: displayName) else { return nil }
        return SubscriptionCurrentPlanViewModel(
            name: plan.name,
            cycle: accountDetails.subscriptionCycle,
            status: status,
            durationMonths: oneOffDurationMonths,
            badgeTitle: badgeTitle,
            now: now
        )
    }

    private var badgeTitle: String? {
        switch accountDetails.subscriptionCycle {
        case .none:
            guard let plan = currentAccountPlan, plan.expirationTime > 0 else { return nil }
            let expiration = Date(timeIntervalSince1970: TimeInterval(plan.expirationTime))
            guard let oneMonthFromNow = Calendar.current.date(byAdding: .month, value: 1, to: now),
                  (now...oneMonthFromNow).contains(expiration) else { return nil }
            return Strings.Localizable.SubscriptionPurchase.Revamp.Badge.expiring
        case .monthly, .yearly:
            // [IOS-12270]: Handle expiring badge for recurring subscriptions.
            return nil
        }
    }

    /// The account plan matching the user's current pro level. Single source of
    /// truth for one-off plan timing (start/expiry).
    private var currentAccountPlan: AccountPlanEntity? {
        accountDetails.plans.first { $0.accountType == accountDetails.proLevel }
    }

    /// Purchased length in months for a one-off (non-recurring) plan, derived from
    /// the plan's start and expiry times. `nil` for recurring plans or when the
    /// SDK hasn't provided a start time.
    private var oneOffDurationMonths: Int? {
        guard accountDetails.subscriptionCycle == .none,
              let plan = currentAccountPlan,
              plan.startTime > 0,
              plan.expirationTime > plan.startTime else { return nil }
        let start = Date(timeIntervalSince1970: TimeInterval(plan.startTime))
        let end = Date(timeIntervalSince1970: TimeInterval(plan.expirationTime))
        // The guard below is to prevent displaying `0 month` duration, in reality this
        // will never happen but I added it here for anyway for better robustness. 
        guard let months = Calendar.current.dateComponents([.month], from: start, to: end).month,
              months >= 1 else { return nil }
        return months
    }

    /// The status line: `.renews` with the renewal date, else `.expires` with the
    private var status: SubscriptionCurrentPlanViewModel.Status? {
        if accountDetails.subscriptionRenewTime > 0 {
            return .renews(Date(timeIntervalSince1970: TimeInterval(accountDetails.subscriptionRenewTime)))
        }
        let expiration = currentAccountPlan.map { TimeInterval($0.expirationTime) }
            ?? TimeInterval(accountDetails.proExpiration)
        if expiration > 0 {
            return .expires(Date(timeIntervalSince1970: expiration))
        }
        return nil
    }

    /// Resolve user's current plan, resolved for its display name. Uses the matched
    /// product plan when available, otherwise a synthetic entity carrying the
    /// account type's display name. `nil` for free accounts.
    static func makeCurrentPlan(
        for details: AccountDetailsEntity,
        in plans: [PlanEntity],
        displayName: (AccountTypeEntity) -> String
    ) -> PlanEntity? {
        let type = details.proLevel
        guard type != .free else { return nil }
        return plans.first { $0.type == type }
            ?? PlanEntity(type: type, name: displayName(type))
    }
}
