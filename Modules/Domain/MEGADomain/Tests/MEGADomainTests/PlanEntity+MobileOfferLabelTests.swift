import Foundation
import MEGADomain
import Testing

struct PlanEntityMobileOfferLabelTests {

    private func mobileOffer(
        useAsTitle: Bool = true,
        label: String? = "Black Friday",
        signed: Bool = false
    ) -> MobileOfferEntity {
        MobileOfferEntity(
            id: "black-friday",
            useAsTitle: useAsTitle,
            label: label,
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

    @Test func withIntroductoryOffer_returnsLabel() {
        let sut = plan(introductory: SubscriptionOfferEntity(price: 10), mobileOffer: mobileOffer())
        #expect(sut.mobileOfferLabel == "Black Friday")
    }

    @Test func withSignedPromotionalOffer_returnsLabel() {
        let sut = plan(promotional: SubscriptionOfferEntity(price: 20), mobileOffer: mobileOffer(signed: true))
        #expect(sut.mobileOfferLabel == "Black Friday")
    }

    @Test func withUnsignedPromotionalOffer_returnsNil() {
        let sut = plan(promotional: SubscriptionOfferEntity(price: 20), mobileOffer: mobileOffer(signed: false))
        #expect(sut.mobileOfferLabel == nil)
    }

    @Test func withoutAnyOffer_returnsNil() {
        let sut = plan(mobileOffer: mobileOffer())
        #expect(sut.mobileOfferLabel == nil)
    }

    /// `useAsTitle` drives the revamp title, not this label, so it must not gate the value.
    @Test func notFlaggedAsTitle_withIntroductoryOffer_stillReturnsLabel() {
        let sut = plan(introductory: SubscriptionOfferEntity(price: 10), mobileOffer: mobileOffer(useAsTitle: false))
        #expect(sut.mobileOfferLabel == "Black Friday")
    }

    @Test func withoutMobileOffer_returnsNil() {
        let sut = plan(introductory: SubscriptionOfferEntity(price: 10))
        #expect(sut.mobileOfferLabel == nil)
    }

    @Test func withNilLabel_returnsNil() {
        let sut = plan(introductory: SubscriptionOfferEntity(price: 10), mobileOffer: mobileOffer(label: nil))
        #expect(sut.mobileOfferLabel == nil)
    }

    /// The SDK returns "" rather than nil when the API omits `mo.l`, so consumers still need their own
    /// emptiness check. Pinning it here so a future change to that contract is deliberate.
    @Test func withEmptyLabel_returnsEmptyStringNotNil() {
        let sut = plan(introductory: SubscriptionOfferEntity(price: 10), mobileOffer: mobileOffer(label: ""))
        #expect(sut.mobileOfferLabel == "")
    }
}
