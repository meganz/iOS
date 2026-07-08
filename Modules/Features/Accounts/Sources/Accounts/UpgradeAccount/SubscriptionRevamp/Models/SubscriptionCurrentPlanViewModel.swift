import MEGADomain

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
        case .yearly: "Yearly subscription" // to be localized later
        case .monthly: "Monthly subscription" // to be localized later
        case .none: nil
        }
    }

    var statusText: String? {
        guard let status else { return nil }
        switch status {
        case .renews: return "Renews on 8 July 2027" // to be localized later
        case .expires: return "Expires on 8 July 2027" // to be localized later
        }
    }
}
