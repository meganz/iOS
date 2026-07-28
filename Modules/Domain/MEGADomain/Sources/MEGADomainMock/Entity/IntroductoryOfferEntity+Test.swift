import Foundation
import MEGADomain

public extension SubscriptionOfferEntity {
    init(
        price: Decimal = 100,
        period: BillingPeriod = .init(unit: .month, value: 1),
        periodCount: Int = 1,
        paymentMode: SubscriptionOfferEntity.PaymentMode = .payAsYouGo,
        isTesting: Bool = true
    ) {
        self.init(
            price: price,
            period: period,
            periodCount: periodCount,
            paymentMode: paymentMode
        )
    }
}
