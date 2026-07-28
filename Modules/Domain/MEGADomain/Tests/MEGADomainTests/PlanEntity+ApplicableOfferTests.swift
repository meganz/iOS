import Foundation
import MEGADomain
import MEGADomainMock
import Testing

struct PlanEntityApplicableOfferTests {

    private func mobileOffer(signed: Bool) -> MobileOfferEntity {
        MobileOfferEntity(
            id: "black-friday",
            useAsTitle: false,
            label: nil,
            discountPercentage: 50,
            flags: 0,
            reshowTimeout: nil,
            expiryDate: nil,
            iosOfferId: "black-friday",
            iosSignature: signed
                ? MobileOfferIosSignatureEntity(offerId: "black-friday", keyId: "key", nonce: "nonce", timestamp: 0, signature: "sig")
                : nil
        )
    }

    private func plan(
        introductory: SubscriptionOfferEntity? = nil,
        promotional: SubscriptionOfferEntity? = nil,
        mobileOffer: MobileOfferEntity? = nil
    ) -> PlanEntity {
        PlanEntity(
            type: .proI,
            currency: "EUR",
            introductoryOffer: introductory,
            mobileOffer: mobileOffer,
            promotionalOffer: promotional
        )
    }

    @Test func introductoryOfferOnly_returnsIntroductoryOffer() {
        let sut = plan(introductory: SubscriptionOfferEntity(price: 10))
        #expect(sut.applicableOffer?.price == 10)
    }

    @Test func validPromotionalOfferOnly_returnsPromotionalOffer() {
        let sut = plan(promotional: SubscriptionOfferEntity(price: 20), mobileOffer: mobileOffer(signed: true))
        #expect(sut.applicableOffer?.price == 20)
    }

    @Test func promotionalOfferWithoutSignature_returnsNil() {
        let sut = plan(promotional: SubscriptionOfferEntity(price: 20), mobileOffer: mobileOffer(signed: false))
        #expect(sut.applicableOffer == nil)
    }

    @Test func promotionalOfferWithoutMobileOffer_returnsNil() {
        let sut = plan(promotional: SubscriptionOfferEntity(price: 20), mobileOffer: nil)
        #expect(sut.applicableOffer == nil)
    }

    @Test func bothOffers_introductoryTakesPriority() {
        let sut = plan(
            introductory: SubscriptionOfferEntity(price: 10),
            promotional: SubscriptionOfferEntity(price: 20),
            mobileOffer: mobileOffer(signed: true)
        )
        #expect(sut.applicableOffer?.price == 10)
    }

    @Test func noOffers_returnsNil() {
        #expect(plan().applicableOffer == nil)
    }
}
