import Foundation
import MEGADomain
import MEGAFoundation
import MEGAL10n

/// Drives the promo header from the discounted plan its screen leads with
/// (introductory or promotional).
///
/// Takes that plan rather than choosing one, so the header always advertises the offer the
/// screen's card shows. Each screen picks by its own rule - the promo page by deepest discount,
/// the landing dialog by lowest monthly price - and a mismatch here would put a discount above
/// a card that doesn't carry it.
///
/// The subtitle reuses the same discount badge shown on the plan card. The validity
/// line and countdown are driven by the plan's `mobileOffer.expiryDate` and
/// appear only for offers that carry one (promotional offers); introductory offers
/// have no expiry. `nil` when the screen has no discounted plan, which empties the subtitle.
struct SubscriptionPromoHeaderViewModel {
    private let plan: PlanEntity?
    private let badgePresenter: SubscriptionOfferBadgePresenter
    private let dateFormatter: any DateFormatting

    init(
        plan: PlanEntity?,
        badgePresenter: SubscriptionOfferBadgePresenter = SubscriptionOfferBadgePresenter(),
        dateFormatter: some DateFormatting = DateFormatter.dateMedium()
    ) {
        self.plan = plan
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
        guard let plan, let badge = badgePresenter.badge(for: plan) else { return "" }
        return badge
    }

    var validUntil: String? {
        guard let expiryDate = plan?.mobileOffer?.expiryDate else { return nil }
        return Strings.Localizable.SubscriptionPurchase.Revamp.Promo.offerEndsOn(dateFormatter.localisedString(from: expiryDate))
    }

    var countdownDeadline: Date? {
        plan?.promotionExpiryDate
    }
}
