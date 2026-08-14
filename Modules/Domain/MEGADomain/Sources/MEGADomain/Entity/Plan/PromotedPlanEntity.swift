import Foundation

/// A plan whose offer is advertisable.
///
/// Exists so that every consumer, such as the landing dialog and the promotion banners,
/// is handed the offer rather than an optional it has to unwrap again.
///
/// Invariants, all established by the `PromotedPlanUseCase`:
///   * `offer` is the plan's own ``PlanEntity/mobileOffer``.
///   * `offer.isAdvertisable` is `true`.
///   * `offer.campaignId` is valid (non-zero)
public struct PromotedPlanEntity: Sendable, Equatable {
    /// The plan on offer, as it goes on to be purchased.
    public let plan: PlanEntity

    /// The advertisable offer attached to `plan`
    public let offer: MobileOfferEntity

    public init(plan: PlanEntity, offer: MobileOfferEntity) {
        self.plan = plan
        self.offer = offer
    }
}
