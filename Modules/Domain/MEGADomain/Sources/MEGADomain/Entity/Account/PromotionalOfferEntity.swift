/// A promotional ("mobile") offer's billing schedule, sourced from StoreKit's promotional offers.
///
/// Shares the shape of ``IntroductoryOfferEntity`` (price, period, periodCount, paymentMode) and is
/// aliased to distinguish promotional offers from introductory offers on ``PlanEntity``.
public typealias PromotionalOfferEntity = IntroductoryOfferEntity
