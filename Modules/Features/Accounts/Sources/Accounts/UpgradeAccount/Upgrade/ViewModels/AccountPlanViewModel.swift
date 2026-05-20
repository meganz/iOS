import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import SwiftUI

@MainActor
public final class AccountPlanViewModel {
    public let plan: PlanEntity
    public let planTag: AccountPlanTagEntity
    public let isSelected: Bool
    public let isSelectionEnabled: Bool
    public let isNewYearlyPlanStyleEnabled: Bool
    public let didTapPlan: () -> Void

    public var planBadge: PlanBadge? {
        switch planTag {
        case .currentPlan: return PlanBadge.currentPlan
        case .recommended: return PlanBadge.recommended
        case .introOffer:
            guard let percentage = plan.introDiscountPercentage else { return nil }
            let text = introOfferBadgeText(percentage: percentage)
            return PlanBadge.discount(text: text)
        case .noTag: return nil
        }
    }

    public init(
        plan: PlanEntity,
        planTag: AccountPlanTagEntity = AccountPlanTagEntity.noTag,
        isSelected: Bool,
        isSelectionEnabled: Bool,
        isNewYearlyPlanStyleEnabled: Bool,
        didTapPlan: @escaping () -> Void
    ) {
        self.plan = plan
        self.planTag = planTag
        self.isSelected = isSelected
        self.isSelectionEnabled = isSelectionEnabled
        self.isNewYearlyPlanStyleEnabled = isNewYearlyPlanStyleEnabled
        self.didTapPlan = didTapPlan
    }

    public func introductoryOfferInfo() -> IntroductoryOfferInfo? {
        guard let introductoryOffer = plan.introductoryOffer else { return nil }

        let period = introductoryOffer.period
        let introPrice = introductoryOffer.price

        guard let formattedFullPrice = formattedPrice(plan.price),
              let formattedIntroPrice = formattedPrice(introPrice) else {
            return nil
        }

        // Convert the intro price to a monthly equivalent
        // The weekly and daily period are not used in production. They are only here for completeness.
        let introPricePerMonth: Decimal = switch period.unit {
        case .year: introPrice / 12
        case .month: introPrice
        case .week: introPrice * 4
        case .day: introPrice * 30
        }

        guard let formattedIntroPricePerMonth = formattedPrice(introPricePerMonth) else {
            return nil
        }

        return .init(
            fullPrice: plan.price,
            formattedFullPrice: formattedFullPrice,
            introPrice: introductoryOffer.price,
            formattedIntroPrice: formattedIntroPrice,
            formattedIntroPricePerMonth: formattedIntroPricePerMonth,
            period: period
        )
    }

    public func formattedPrice(_ price: Decimal) -> String? {
        numberFormatter.string(for: price)
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = plan.currency
        return formatter
    }

    private func introOfferBadgeText(percentage: Int) -> String {
        let discount = "\(percentage)%"
        if let label = plan.mobileOfferLabel, !label.isEmpty {
            return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOfferLabel(label, discount)
        }
        return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOffer(discount)
    }
}
