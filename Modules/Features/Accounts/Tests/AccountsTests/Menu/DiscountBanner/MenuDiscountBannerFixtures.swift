@testable import Accounts
import Foundation
import MEGADomain
import MEGADomainMock

extension PlanEntity {
    static func menuBannerPlan(
        label: String? = "Black Friday",
        campaignId: UInt64 = 7,
        expiryDate: Date? = nil,
        iosSignature: MobileOfferIosSignatureEntity? = nil,
        introductoryOffer: SubscriptionOfferEntity? = nil,
        promotionalOffer: SubscriptionOfferEntity? = nil
    ) -> PlanEntity {
        PlanEntity(
            productIdentifier: "pro.i.monthly",
            type: .proI,
            subscriptionCycle: .monthly,
            introductoryOffer: introductoryOffer,
            mobileOffer: MobileOfferEntity(
                id: "black-friday-2025",
                useAsTitle: false,
                label: label,
                discountPercentage: 50,
                flags: 1,
                reshowTimeout: nil,
                expiryDate: expiryDate,
                iosOfferId: nil,
                iosSignature: iosSignature,
                campaignId: campaignId
            ),
            promotionalOffer: promotionalOffer
        )
    }
}

extension SubscriptionPlanPrice {
    static func discounted(percentage: Int, pricePerMonth: Decimal = 4.99) -> SubscriptionPlanPrice {
        .discountMonthly(
            .init(
                monthly: .init(price: 9.99, currency: "EUR"),
                offer: .init(
                    originalPrice: 9.99,
                    discountPercentage: percentage,
                    schedule: .recurring(
                        price: pricePerMonth,
                        period: BillingPeriod(unit: .month, value: 1),
                        periodCount: 1
                    )
                )
            )
        )
    }
}

extension SubscriptionOfferEntity {
    static var stub: SubscriptionOfferEntity {
        SubscriptionOfferEntity(
            price: 4.99,
            period: BillingPeriod(unit: .month, value: 1),
            periodCount: 1,
            paymentMode: .payAsYouGo
        )
    }
}

extension MobileOfferIosSignatureEntity {
    static var stub: MobileOfferIosSignatureEntity {
        MobileOfferIosSignatureEntity(
            offerId: "offer",
            keyId: "key",
            nonce: "nonce",
            timestamp: 1,
            signature: "signature"
        )
    }
}

extension MenuDiscountBannerContentMapper {
    static func stub(planPrice: SubscriptionPlanPrice) -> MenuDiscountBannerContentMapper {
        MenuDiscountBannerContentMapper(
            planPriceUseCase: MockSubscriptionPlanPriceUseCase(planPrice: planPrice),
            displayName: { _ in "Pro I" },
            locale: Locale(identifier: "en_US")
        )
    }
}
