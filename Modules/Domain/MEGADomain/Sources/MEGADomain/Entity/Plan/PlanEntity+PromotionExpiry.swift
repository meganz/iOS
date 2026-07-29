public extension PlanEntity {
    /// The plan with its promotional offer stripped, used once the promotion has lapsed so no stale
    /// discount survives. Introductory offers are left intact, since they never expire.
    func removingPromotionalOffer() -> PlanEntity {
        var plan = self
        plan.promotionalOffer = nil
        plan.mobileOffer = nil
        return plan
    }
}
