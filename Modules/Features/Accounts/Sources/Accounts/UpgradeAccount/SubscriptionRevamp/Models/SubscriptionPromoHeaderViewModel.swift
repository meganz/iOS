import Foundation
import MEGADomain
import MEGAFoundation
import MEGAL10n

/// Drives the promo header from the plan with the highest applicable discount
/// (introductory or promotional).
///
/// The subtitle reuses the same discount badge shown on the plan card. The validity
/// line and countdown are driven by the featured plan's `mobileOffer.expiryDate` and
/// appear only for offers that carry one (promotional offers); introductory offers
/// have no expiry. Initialisation fails when no plan has an applicable offer, so the
/// header is hidden.
struct SubscriptionPromoHeaderViewModel {
    private let plans: [PlanEntity]
    private let badgePresenter: SubscriptionOfferBadgePresenter
    private let dateFormatter: any DateFormatting

    init(
        plans: [PlanEntity],
        badgePresenter: SubscriptionOfferBadgePresenter = SubscriptionOfferBadgePresenter(),
        dateFormatter: some DateFormatting = DateFormatter.dateMedium()
    ) {
        self.plans = plans
        self.badgePresenter = badgePresenter
        self.dateFormatter = dateFormatter
    }

    var tag: String {
        Strings.Localizable.SubscriptionPurchase.Revamp.Promo.specialOffer
    }

    var title: String {
        Strings.Localizable.SubscriptionPurchase.title
    }

    var subtitle: String {
        guard let featuredPlan, let badge = badgePresenter.badge(for: featuredPlan) else { return "" }
        return badge
    }

    var validUntil: String? {
        guard let expiryDate = featuredPlan?.mobileOffer?.expiryDate else { return nil }
        return Strings.Localizable.SubscriptionPurchase.Revamp.Promo.offerEndsOn(dateFormatter.localisedString(from: expiryDate))
    }

    var countdownDeadline: Date? {
        guard let featuredPlan = featuredPlan, featuredPlan.hasValidPromotionalOffer else { return nil }
        return featuredPlan.mobileOffer?.expiryDate
    }

    private var featuredPlan: PlanEntity? {
        highestDiscountPlan()
    }

    private func highestDiscountPlan() -> PlanEntity? {
        plans
            .filter { $0.applicableOffer != nil }
            .max { (badgePresenter.discountPercentage(for: $0) ?? 0) < (badgePresenter.discountPercentage(for: $1) ?? 0) }
    }
}
