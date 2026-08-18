/// The outcome of a promoted plan fetch: the plan to advertise, and whether it is the only one on offer.
public struct PromotedPlanFetchResult: Sendable, Equatable {
    /// The plan to advertise.
    public let promotedPlan: PromotedPlanEntity

    /// Whether plans besides `promotedPlan` carry an advertisable offer too
    public let hasMultipleOffers: Bool

    public init(promotedPlan: PromotedPlanEntity, hasMultipleOffers: Bool) {
        self.promotedPlan = promotedPlan
        self.hasMultipleOffers = hasMultipleOffers
    }
}
