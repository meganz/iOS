import MEGADomain

extension PlanEntity {
    /// Whether this plan is the one the user currently owns: same level and same billing cycle.
    func isCurrentPlan(for accountDetails: AccountDetailsEntity) -> Bool {
        type == accountDetails.proLevel && subscriptionCycle == accountDetails.subscriptionCycle
    }
}
