import Foundation
import MEGADomain
import MEGAL10n
import MEGAUIComponent

/// Maps the business-resolved ``SubscriptionPlanPrice`` to the view-layer `PlanPrice`.
public struct RecommendedPlanPriceMapper {
    /// Injected so currency formatting is locale-stable (tests pin it); production uses the current locale.
    private let locale: Locale

    public init(locale: Locale = .autoupdatingCurrent) {
        self.locale = locale
    }

    public func map(_ price: SubscriptionPlanPrice) -> PlanPrice {
        switch price {
        case let .monthly(model):
            .monthly(PlanPriceModel.Monthly(pricePerMonth: perMonth(model.price, model.currency)))
        case let .yearly(model):
            .yearly(
                PlanPriceModel.Yearly(
                    pricePerMonth: perMonth(model.price / 12, model.currency),
                    billingCaption: Strings.Localizable.SubscriptionPurchase.Plan.billedYearly(formattedCurrency(model.price, model.currency))
                )
            )
        case let .discountMonthly(model):
            .discountMonthly(discountMonthly(model))
        case let .discountYearly(model):
            .discountYearly(discountYearly(model))
        }
    }

    private func discountMonthly(_ model: SubscriptionPlanPrice.DiscountMonthly) -> PlanPriceModel.DiscountMonthly {
        PlanPriceModel.DiscountMonthly(
            priceLine: discountedPriceLine(model.offer, model.monthly.currency),
            billingCaption: monthlyDiscountBillingCaption(model)
        )
    }

    private func discountYearly(_ model: SubscriptionPlanPrice.DiscountYearly) -> PlanPriceModel.DiscountYearly {
        let currencyCode = model.yearly.currency
        return .init(
            pricePerMonth: perMonth(model.offer.schedule.pricePerMonth, currencyCode),
            priceLine: discountedPriceLine(model.offer, currencyCode),
            billingCaption: yearlyDiscountBillingCaption(model)
        )
    }

    /// Fills the localised discounted price sentence, e.g. "[A]€59.94[/A] €29.94 for 6 months".
    private func discountedPriceLine(_ offer: SubscriptionPlanPrice.Offer, _ currencyCode: String) -> String {
        discountedPriceSentence(offer.schedule)
            .replacingOccurrences(of: "[A]", with: "[A]\(formattedCurrency(offer.originalPrice, currencyCode))[/A]")
            .replacingOccurrences(of: "[B]", with: formattedCurrency(offer.schedule.price, currencyCode))
    }

    private func discountedPriceSentence(_ schedule: OfferBillingSchedule) -> String {
        switch schedule {
        case let .recurring(_, period, _): perCycleDiscountSentence(period.unit)
        case let .prepaid(_, period): forSpanDiscountSentence(period)
        case let .free(period): forSpanDiscountSentence(period)
        }
    }

    /// "[A] [B]/month" | "[A] [B]/year"
    private func perCycleDiscountSentence(_ periodUnit: BillingPeriodUnit) -> String {
        switch periodUnit {
        case .month: Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.discountPriceMonthlyRate
        case .year: Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.discountPriceYearlyRate
        }
    }

    /// "[A] [B] for x months" | "[A] [B] for x years"
    private func forSpanDiscountSentence(_ period: BillingPeriod) -> String {
        switch period.unit {
        case .month: Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.discountPriceForMonths(period.value)
        case .year: Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.discountPriceForYears(period.value)
        }
    }

    private func monthlyDiscountBillingCaption(_ model: SubscriptionPlanPrice.DiscountMonthly) -> String {
        let schedule = model.offer.schedule
        let currencyCode = model.monthly.currency
        let renewalPrice = model.monthly.price

        return switch schedule {
        case .recurring(let price, _, let periodCount):
            billRecurringOfferThenRenewMonthly(price, renewalPrice, currencyCode, periodCount: periodCount)
        case .prepaid(let price, let period):
            billUpfrontOfferThenRenewMonthly(price, renewalPrice, currencyCode, period: period)
        case .free(let period):
            billUpfrontOfferThenRenewMonthly(0, renewalPrice, currencyCode, period: period)
        }
    }

    /// Pay-as-you-go on a **monthly** plan. The offer bills once per month, so `periodCount` *is* the number of
    /// discounted months and the "recurring months" copy is always the right one. The offer's `period`
    /// (always 1 month here) carries no extra information and is intentionally ignored.
    private func billRecurringOfferThenRenewMonthly(_ offerPrice: Decimal, _ renewalPrice: Decimal, _ currencyCode: String, periodCount: Int) -> String {
        Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.introBilledMonthlyRecurringMonths(periodCount)
            .replacingOccurrences(of: "[A]", with: formattedCurrency(offerPrice, currencyCode))
            .replacingOccurrences(of: "[B]", with: formattedCurrency(renewalPrice, currencyCode))
    }

    private func billUpfrontOfferThenRenewMonthly(_ offerPrice: Decimal, _ renewalPrice: Decimal, _ currencyCode: String, period: BillingPeriod) -> String {
        switch period.unit {
        case .month:
            Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.introBilledMonthlyTotalMonths(period.value)
                .replacingOccurrences(of: "[A]", with: formattedCurrency(offerPrice, currencyCode))
                .replacingOccurrences(of: "[B]", with: formattedCurrency(renewalPrice, currencyCode))
        case .year:
            Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.introBilledMonthlyTotalYears(period.value)
                .replacingOccurrences(of: "[A]", with: formattedCurrency(offerPrice, currencyCode))
                .replacingOccurrences(of: "[B]", with: formattedCurrency(renewalPrice, currencyCode))
        }
    }

    private func yearlyDiscountBillingCaption(_ model: SubscriptionPlanPrice.DiscountYearly) -> String {
        let schedule = model.offer.schedule
        let currencyCode = model.yearly.currency
        let renewalPrice = model.yearly.price

        return switch schedule {
        case .recurring(let price, _, let periodCount):
            billRecurringOfferThenRenewYearly(price, renewalPrice, currencyCode, periodCount: periodCount)
        case .prepaid(let price, let period):
            billUpfrontOfferThenRenewYearly(price, renewalPrice, currencyCode, period: period)
        case .free(let period):
            billUpfrontOfferThenRenewYearly(0, renewalPrice, currencyCode, period: period)
        }
    }

    /// Pay-as-you-go on a **yearly** plan. The offer bills once per year, so `periodCount` *is* the number of
    /// discounted years and the "yearly years" copy is always the right one. The offer's `period`
    /// (always 1 year here) carries no extra information and is intentionally ignored.
    private func billRecurringOfferThenRenewYearly(_ offerPrice: Decimal, _ renewalPrice: Decimal, _ currencyCode: String, periodCount: Int) -> String {
        Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.introBilledYearlyYears(periodCount)
            .replacingOccurrences(of: "[A]", with: formattedCurrency(offerPrice, currencyCode))
            .replacingOccurrences(of: "[B]", with: formattedCurrency(renewalPrice, currencyCode))
    }

    private func billUpfrontOfferThenRenewYearly(_ offerPrice: Decimal, _ renewalPrice: Decimal, _ currencyCode: String, period: BillingPeriod) -> String {
        switch period.unit {
        case .month:
            Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.introBilledYearlyMonths(period.value)
                .replacingOccurrences(of: "[A]", with: formattedCurrency(offerPrice, currencyCode))
                .replacingOccurrences(of: "[B]", with: formattedCurrency(renewalPrice, currencyCode))
        case .year:
            Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.introBilledYearlyYears(period.value)
                .replacingOccurrences(of: "[A]", with: formattedCurrency(offerPrice, currencyCode))
                .replacingOccurrences(of: "[B]", with: formattedCurrency(renewalPrice, currencyCode))
        }
    }

    /// "XX/month"
    private func perMonth(_ value: Decimal, _ currencyCode: String) -> String {
        Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.localCurrencyPerMonth(formattedCurrency(value, currencyCode))
    }

    /// Use rounding rule toNearestOrEven to keep consistent with current halfEven rounding mode.
    private func formattedCurrency(_ value: Decimal, _ code: String) -> String {
        value.formatted(
            Decimal
                .FormatStyle
                .Currency(code: code, locale: locale)
                .rounded(rule: .toNearestOrEven)
        )
    }
}
