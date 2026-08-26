import Foundation

public extension PlanEntity {
    /// When the plan's promotional offer lapses, or `nil` when it carries no expiring promotional
    /// offer. Introductory offers never expire, so they have no deadline here.
    var promotionExpiryDate: Date? {
        guard hasValidPromotionalOffer else { return nil }
        return mobileOffer?.expiryDate
    }

    /// The plan with its promotional offer stripped, used once the promotion has lapsed so no stale
    /// discount survives. Introductory offers are left intact, since they never expire.
    func removingPromotionalOffer() -> PlanEntity {
        var plan = self
        plan.promotionalOffer = nil
        return plan
    }
}
