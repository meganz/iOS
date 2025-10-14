import MEGADomain
import StoreKit

extension IntroductoryOfferEntity {
    public static func from(storeKitOffer: Product.SubscriptionOffer) -> IntroductoryOfferEntity? {
        let price = storeKitOffer.price
        let period = storeKitOffer.period
        let periodCount = storeKitOffer.periodCount

        let unit: SubscriptionPeriod.Unit? = switch period.unit {
        case .day: .day
        case .week: .week
        case .month: .month
        case .year:  .year
        @unknown default: nil
        }
        guard let unit else { return nil }
        
        let subscriptionPeriod = SubscriptionPeriod(unit: unit, value: period.value)

        return IntroductoryOfferEntity(
            price: price,
            period: subscriptionPeriod,
            periodCount: periodCount
        )
    }
}
