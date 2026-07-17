import Foundation

public protocol SubscriptionPlanPriceUseCaseProtocol: Sendable {
    /// Maps a ``PlanEntity`` to a ``SubscriptionPlanPrice`` by applying the pricing business rules
    func planPrice(for plan: PlanEntity) -> SubscriptionPlanPrice
}

public struct SubscriptionPlanPriceUseCase: SubscriptionPlanPriceUseCaseProtocol {
    public init() {}

    public func planPrice(for plan: PlanEntity) -> SubscriptionPlanPrice {
        guard let offer = plan.introductoryOffer else {
            return nonDiscountPrice(for: plan)
        }
        return discountPrice(for: plan, schedule: offer.billingSchedule)
    }

    // MARK: - No discount

    private func nonDiscountPrice(for plan: PlanEntity) -> SubscriptionPlanPrice {
        switch plan.subscriptionCycle {
        case .yearly:
                .yearly(SubscriptionPlanPrice.Yearly(price: plan.price, currency: plan.currency))
        case .monthly, .none:
                .monthly(SubscriptionPlanPrice.Monthly(price: plan.price, currency: plan.currency))
        }
    }

    // MARK: - Discount

    private func discountPrice(for plan: PlanEntity, schedule: OfferBillingSchedule) -> SubscriptionPlanPrice {
        let totalMonths = Decimal(schedule.totalMonths)
        let percentage = discountPercentage(fullPrice: plan.price, schedule: schedule, cycle: plan.subscriptionCycle)

        switch plan.subscriptionCycle {
        case .yearly:
            let yearly = SubscriptionPlanPrice.Yearly(price: plan.price, currency: plan.currency)
            // The originalPrice price is the full price over the intro span.
            // It is the per-month equivalent × span.
            let originalPrice = (plan.price * totalMonths) / 12
            return .discountYearly(
                SubscriptionPlanPrice.DiscountYearly(
                    yearly: yearly,
                    offer: SubscriptionPlanPrice.Offer(originalPrice: originalPrice, discountPercentage: percentage, schedule: schedule)
                )
            )
        case .monthly, .none:
            let monthly = SubscriptionPlanPrice.Monthly(price: plan.price, currency: plan.currency)
            // The originalPrice represents:
            // - the regular monthly price for recurring offers
            // - the regular price for the full offer period for prepaid and free offers
            let originalPrice: Decimal = switch schedule {
            case .recurring: plan.price
            case .prepaid, .free: plan.price * totalMonths
            }
            return .discountMonthly(.init(
                monthly: monthly,
                offer: .init(originalPrice: originalPrice, discountPercentage: percentage, schedule: schedule)
            ))
        }
    }

    /// The discount as a whole percentage: `1 - introPricePerMonth / fullPricePerMonth`, over the same span.
    ///
    /// Divides only once, at the end, to avoid repeating-decimal rounding (IOS-12214): the yearly case
    /// multiplies the intro total by 12 rather than dividing the full price by 12 early. Returns `0` for a
    /// degenerate offer (non-positive full price or empty span) so it never divides by zero and the ribbon
    /// simply treats it as "no discount".
    private func discountPercentage(fullPrice: Decimal, schedule: OfferBillingSchedule, cycle: SubscriptionCycleEntity) -> Int {
        let totalMonths = Decimal(schedule.totalMonths)
        guard fullPrice > 0, totalMonths > 0 else { return 0 }

        let ratio: Decimal = switch cycle {
        case .none, .monthly: schedule.totalPrice / (totalMonths * fullPrice)
        case .yearly: (12 * schedule.totalPrice) / (totalMonths * fullPrice)
        }
        let percentage = (1 - ratio) * 100
        return NSDecimalNumber(decimal: percentage).rounding(accordingToBehavior: nil).intValue
    }
}
