import Foundation

public extension SubscriptionOfferEntity {
    /// The billing schedule (payment mode + period) this offer resolves to.
    ///
    /// This is the single source of truth for the offer's derived amounts — read `totalMonths`,
    /// `totalPrice` and `pricePerMonth` off the returned `OfferBillingSchedule`.
    ///
    /// `periodCount` is only meaningful for pay-as-you-go (`.recurring`); pay-up-front and free trials
    /// always cover the whole span in a single `period` (`periodCount == 1`), so it is not carried.
    var billingSchedule: OfferBillingSchedule {
        switch paymentMode {
        case .payAsYouGo:
            .recurring(price: price, period: period, periodCount: periodCount)
        case .payUpFront:
            .prepaid(price: price, period: period)
        case .freeTrial:
            .free(period: period)
        }
    }
}
