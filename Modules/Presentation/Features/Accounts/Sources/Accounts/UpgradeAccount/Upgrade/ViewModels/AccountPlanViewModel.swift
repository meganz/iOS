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
    public let didTapPlan: () -> Void

    private let now: () -> Date
    private let calendar: Calendar
    private let timeZone: TimeZone

    public var planBadge: PlanBadge? {
        switch planTag {
        case .currentPlan: return PlanBadge.currentPlan
        case .recommended: return PlanBadge.recommended
        case .introOffer:
            guard let percentage = plan.introDiscountPercentage else { return nil}
            let text = introOfferBadgeText(percentage: percentage)
            return PlanBadge.discount(text: text)
        case .none: return nil
        }
    }
    
    public init(
        plan: PlanEntity,
        planTag: AccountPlanTagEntity = AccountPlanTagEntity.none,
        isSelected: Bool,
        isSelectionEnabled: Bool,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = Calendar.current,
        timeZone: TimeZone = TimeZone.current,
        didTapPlan: @escaping () -> Void
    ) {
        self.plan = plan
        self.planTag = planTag
        self.isSelected = isSelected
        self.isSelectionEnabled = isSelectionEnabled
        self.now = now
        self.calendar = calendar
        self.timeZone = timeZone
        self.didTapPlan = didTapPlan
    }

    public func introductoryOfferInfo() -> IntroductoryOfferInfo? {
        guard let introductoryOffer = plan.introductoryOffer else { return nil}

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
        let now = now()
        let year = calendar.component(.year, from: now)

        // Build date boundaries in the specified timezone.
        // [Now ... 7 Dec 23:59:59] -> blackFridayDeal
        // [8 Dec 00:00:00 ... ] -> generalDeal
        guard let dec8End = date(year, 12, 7, 23, 59, 59) else {
            return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.generalDeal("\(percentage)%")
        }

        if now <= dec8End {
            return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.blackFridayDeal("\(percentage)%")
        } else {
            return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.generalDeal("\(percentage)%")
        }
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int, _ s: Int) -> Date? {
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d
        comps.hour = h; comps.minute = min; comps.second = s
        comps.timeZone = timeZone
        return calendar.date(from: comps)
    }
}
