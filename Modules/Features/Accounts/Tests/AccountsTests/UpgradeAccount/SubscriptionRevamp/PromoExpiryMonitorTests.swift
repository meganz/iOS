@testable import Accounts
import Foundation
import MEGADomain
import MEGADomainMock
import Testing

@MainActor
@Suite("PromoExpiryMonitor")
struct PromoExpiryMonitorTests {

    private func mobileOffer() -> MobileOfferEntity {
        MobileOfferEntity(
            id: "black-friday",
            useAsTitle: false,
            label: nil,
            discountPercentage: 50,
            flags: 0,
            reshowTimeout: nil,
            expiryDate: nil,
            iosOfferId: "black-friday",
            iosSignature: MobileOfferIosSignatureEntity(offerId: "black-friday", keyId: "key", nonce: "nonce", timestamp: 0, signature: "sig")
        )
    }

    private func makeSUT(
        deadline: Date,
        plans: [PlanEntity] = []
    ) -> PromoExpiryMonitor {
        PromoExpiryMonitor(deadline: deadline, accountDetails: .build(), plans: plans)
    }

    // MARK: - hasAlreadyExpired

    @Test func hasAlreadyExpired_isTrueForPastDeadline() {
        let sut = makeSUT(deadline: Date().addingTimeInterval(-1))
        #expect(sut.hasAlreadyExpired)
    }

    @Test func hasAlreadyExpired_isFalseForFutureDeadline() {
        let sut = makeSUT(deadline: Date().addingTimeInterval(1000))
        #expect(sut.hasAlreadyExpired == false)
    }

    // MARK: - waitUntilExpired

    @Test func waitUntilExpired_whenDeadlineAlreadyPassed_returnsTrueImmediately() async {
        let sut = makeSUT(deadline: Date().addingTimeInterval(-1))
        #expect(await sut.waitUntilExpired())
    }

    @Test func waitUntilExpired_whenCancelledBeforeDeadline_returnsFalse() async {
        let sut = makeSUT(deadline: Date().addingTimeInterval(1000))
        let task = Task { await sut.waitUntilExpired() }
        task.cancel()
        #expect(await task.value == false)
    }

    // MARK: - plansAfterExpiry

    @Test func plansAfterExpiry_stripsPromotionalOffersButKeepsIntroAndPrice() {
        let promoPlan = PlanEntity(
            type: .proI,
            currency: "EUR",
            price: 10,
            introductoryOffer: SubscriptionOfferEntity(price: 5),
            mobileOffer: mobileOffer(),
            promotionalOffer: SubscriptionOfferEntity(price: 20)
        )
        let sut = makeSUT(deadline: Date().addingTimeInterval(1000), plans: [promoPlan])

        let stripped = sut.plansAfterExpiry
        #expect(stripped.count == 1)
        #expect(stripped.first?.promotionalOffer == nil)
        #expect(stripped.first?.mobileOffer == nil)
        #expect(stripped.first?.introductoryOffer?.price == 5)
        #expect(stripped.first?.price == 10)
    }

    @Test func plansAfterExpiry_isEmptyForNoPlans() {
        let sut = makeSUT(deadline: Date().addingTimeInterval(1000))
        #expect(sut.plansAfterExpiry.isEmpty)
    }
}

struct PlanEntityPromotionExpiryTests {
    private func mobileOffer() -> MobileOfferEntity {
        MobileOfferEntity(
            id: "black-friday",
            useAsTitle: false,
            label: nil,
            discountPercentage: 50,
            flags: 0,
            reshowTimeout: nil,
            expiryDate: nil,
            iosOfferId: "black-friday",
            iosSignature: MobileOfferIosSignatureEntity(offerId: "black-friday", keyId: "key", nonce: "nonce", timestamp: 0, signature: "sig")
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
            price: 10,
            introductoryOffer: introductory,
            mobileOffer: mobileOffer,
            promotionalOffer: promotional
        )
    }

    @Test func removesPromotionalOffer() {
        let sut = plan(promotional: SubscriptionOfferEntity(price: 20), mobileOffer: mobileOffer())
        #expect(sut.removingPromotionalOffer().promotionalOffer == nil)
    }

    @Test func removesMobileOffer() {
        let sut = plan(promotional: SubscriptionOfferEntity(price: 20), mobileOffer: mobileOffer())
        #expect(sut.removingPromotionalOffer().mobileOffer == nil)
    }

    @Test func strippedPlanHasNoValidPromotionalOffer() {
        let sut = plan(promotional: SubscriptionOfferEntity(price: 20), mobileOffer: mobileOffer())
        #expect(sut.hasValidPromotionalOffer)
        #expect(sut.removingPromotionalOffer().hasValidPromotionalOffer == false)
    }

    @Test func keepsIntroductoryOfferAndFullPrice() {
        let sut = plan(
            introductory: SubscriptionOfferEntity(price: 5),
            promotional: SubscriptionOfferEntity(price: 20),
            mobileOffer: mobileOffer()
        )
        let stripped = sut.removingPromotionalOffer()
        #expect(stripped.introductoryOffer?.price == 5)
        #expect(stripped.price == 10)
        #expect(stripped.type == .proI)
        #expect(stripped.applicableOffer?.price == 5)
    }

    @Test func planWithoutPromotionalOfferIsUnchanged() {
        let sut = plan(introductory: SubscriptionOfferEntity(price: 5))
        let stripped = sut.removingPromotionalOffer()
        #expect(stripped.promotionalOffer == nil)
        #expect(stripped.mobileOffer == nil)
        #expect(stripped.introductoryOffer?.price == 5)
    }
}
