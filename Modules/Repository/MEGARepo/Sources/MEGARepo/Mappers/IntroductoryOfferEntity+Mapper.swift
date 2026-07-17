import MEGADomain
import StoreKit

extension IntroductoryOfferEntity {
    public static func from(storeKitOffer: Product.SubscriptionOffer) -> IntroductoryOfferEntity? {
        let price = storeKitOffer.price
        let period = storeKitOffer.period
        let periodCount = storeKitOffer.periodCount

        // MEGA only ships monthly / yearly products. Day- and week-based offers are not supported, so
        // they (and any future unit) are dropped — the plan is then treated as having no offer.
        let unit: BillingPeriodUnit? = switch period.unit {
        case .month: .month
        case .year: .year
        case .day, .week: nil
        @unknown default: nil
        }
        guard let unit else { return nil }

        let billingPeriod = BillingPeriod(unit: unit, value: period.value)

        let paymentMode: PaymentMode = switch storeKitOffer.paymentMode {
        case .payAsYouGo: .payAsYouGo
        case .payUpFront: .payUpFront
        case .freeTrial: .freeTrial
        default: .payAsYouGo
        }

        return IntroductoryOfferEntity(
            price: price,
            period: billingPeriod,
            periodCount: periodCount,
            paymentMode: paymentMode
        )
    }
}
