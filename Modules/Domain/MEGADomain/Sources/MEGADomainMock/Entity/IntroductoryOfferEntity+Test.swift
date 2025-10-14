import Foundation
import MEGADomain

public extension IntroductoryOfferEntity {
    init(
        price: Decimal = 100,
        period: IntroductoryOfferEntity.SubscriptionPeriod = .init(unit: .month, value: 1),
        periodCount: Int = 1,
        isTesting: Bool = true
    ) {
        self.init(
            price: price,
            period: period,
            periodCount: periodCount
        )
    }
}
