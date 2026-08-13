import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n

struct MenuDiscountBannerContent: Equatable, Sendable {
    let message: String
    let actionTitle: String
    let deadline: Date?
}

public struct MenuDiscountBannerContentMapper: Sendable {
    private let planPriceUseCase: any SubscriptionPlanPriceUseCaseProtocol
    private let displayName: @Sendable (AccountTypeEntity) -> String
    private let locale: Locale

    public init(
        planPriceUseCase: some SubscriptionPlanPriceUseCaseProtocol = SubscriptionPlanPriceUseCase(),
        displayName: @escaping @Sendable (AccountTypeEntity) -> String = { $0.toAccountTypeDisplayName() },
        locale: Locale = .autoupdatingCurrent
    ) {
        self.planPriceUseCase = planPriceUseCase
        self.displayName = displayName
        self.locale = locale
    }

    func map(_ plan: PlanEntity) -> MenuDiscountBannerContent? {
        guard let discount = discount(for: planPriceUseCase.planPrice(for: plan)),
              discount.offer.discountPercentage > 0 else { return nil }

        return MenuDiscountBannerContent(
            message: Strings.Localizable.Home.PromotionalBanners.DiscountBanner.message(
                label(for: plan),
                "\(discount.offer.discountPercentage)%",
                formattedCurrency(discount.offer.schedule.pricePerMonth, discount.currency),
                displayName(plan.type)
            ),
            actionTitle: Strings.Localizable.Home.PromotionalBanners.DiscountBanner.grabDeal,
            deadline: deadline(for: plan)
        )
    }

    private func deadline(for plan: PlanEntity) -> Date? {
        guard plan.hasValidPromotionalOffer else { return nil }
        return plan.mobileOffer?.expiryDate
    }

    private func label(for plan: PlanEntity) -> String {
        guard let label = plan.mobileOfferLabel, !label.isEmpty else {
            return Strings.Localizable.SubscriptionPurchase.Revamp.Promo.specialOffer
        }
        return label
    }

    private func discount(for price: SubscriptionPlanPrice) -> (offer: SubscriptionPlanPrice.Offer, currency: String)? {
        switch price {
        case .discountMonthly(let model): (model.offer, model.monthly.currency)
        case .discountYearly(let model): (model.offer, model.yearly.currency)
        case .monthly, .yearly: nil
        }
    }

    private func formattedCurrency(_ value: Decimal, _ code: String) -> String {
        value.formatted(
            Decimal
                .FormatStyle
                .Currency(code: code, locale: locale)
                .rounded(rule: .toNearestOrEven)
        )
    }
}
