import MEGADomain
import MEGAL10n

struct SubscriptionCurrentPlanViewModel: Equatable {
    enum Status: Equatable {
        case renews
        case expires
    }

    let plan: PlanEntity
    let status: Status?
    let badgeTitle: String?

    init(
        plan: PlanEntity,
        status: Status? = nil,
        badgeTitle: String? = nil
    ) {
        self.plan = plan
        self.status = status
        self.badgeTitle = badgeTitle
    }

    // MARK: - Display

    var name: String { plan.name }

    var cycleText: String? {
        switch plan.subscriptionCycle {
        case .yearly: Strings.Localizable.SubscriptionPurchase.Revamp.Cycle.yearly
        case .monthly: Strings.Localizable.SubscriptionPurchase.Revamp.Cycle.monthly
        case .none: nil
        }
    }

    var statusText: String? {
        guard let status else { return nil }
        switch status {
        case .renews: return Strings.Localizable.Account.Profile.Renewal.future(endOfCycleText)
        case .expires: return Strings.Localizable.Account.Profile.Expiry.future(endOfCycleText)
        }
    }

    private var endOfCycleText: String {
        "8 July 2027" // [IOS-12185]: Compute the actual end of cycle
    }
}
