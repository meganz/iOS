import Foundation
import MEGADomain
import MEGADomainMock
import Testing

struct PlanEntityTests {
    @Test(
        arguments: [
            (100, 80 ,20),
            (100, 50 ,50),
            (100, 90.5 ,10),
            (100, 89.4 ,11),
            (1.99, 0.99 ,50)
        ]
    )
    func introductoryDiscountPercentage(
        fullPrice: Decimal,
        introPrice: Decimal,
        expectedPercentage: Int
    ) {
        let introOffer = IntroductoryOfferEntity(
            price: introPrice,
            period: .init(unit: .year, value: 1),
            periodCount: 1
        )
        let plan = PlanEntity(
            type: .proI,
            subscriptionCycle: .yearly,
            appStorePrice: .init(price: fullPrice, formattedPrice: "$100", currency: "USD"),
            introductoryOffer: introOffer
        )

        #expect(plan.introDiscountPercentage == expectedPercentage)
    }


    @Test
    func introductoryDiscountPercentage_whenWithoutIntroOffer_shouldBeNil() {
        let plan = PlanEntity(
            type: .proI,
            subscriptionCycle: .yearly,
            appStorePrice: .init(price: 100, formattedPrice: "$100", currency: "USD"),
            introductoryOffer: nil
        )

        #expect(plan.introDiscountPercentage == nil)
    }
}
