@testable import Accounts
import MEGADomain
import MEGAL10n
import Testing

@Suite("ExternalPurchasePresenter - buy on our website button mapping")
struct ExternalPurchasePresenterTests {

    // MARK: - isExternalPurchaseEnabled

    @Test("A plan carrying an API price and no offer can be bought on the website")
    func isExternalPurchaseEnabled_withAPIPriceAndNoOffer_isTrue() {
        #expect(makeSUT().isExternalPurchaseEnabled(for: plan()))
    }

    @Test("A plan without an API price cannot be bought on the website")
    func isExternalPurchaseEnabled_withoutAPIPrice_isFalse() {
        #expect(makeSUT().isExternalPurchaseEnabled(for: plan(apiPrice: nil)) == false)
    }

    @Test("A plan with an introductory offer cannot be bought on the website")
    func isExternalPurchaseEnabled_withIntroductoryOffer_isFalse() {
        #expect(makeSUT().isExternalPurchaseEnabled(for: plan(introductoryOffer: offer())) == false)
    }

    @Test("A plan with a valid promotional offer cannot be bought on the website")
    func isExternalPurchaseEnabled_withValidPromotionalOffer_isFalse() {
        let discounted = plan(promotionalOffer: offer(), mobileOffer: signedMobileOffer())
        #expect(makeSUT().isExternalPurchaseEnabled(for: discounted) == false)
    }

    @Test("A promotional offer the API has not signed leaves the plan buyable on the website")
    func isExternalPurchaseEnabled_withUnsignedPromotionalOffer_isTrue() {
        #expect(makeSUT().isExternalPurchaseEnabled(for: plan(promotionalOffer: offer())))
    }

    // MARK: - externalPurchaseTitle

    @Test("An eligible plan carries the savings title")
    func externalPurchaseTitle_withEligiblePlan_isTheSavingsTitle() {
        let expected = Strings.Localizable.SubscriptionPurchase.Revamp.Button.BuyOnWebsite.saveUpTo("15%")
        #expect(makeSUT().externalPurchaseTitle(for: plan()) == expected)
    }

    @Test("An ineligible plan carries no title")
    func externalPurchaseTitle_withIneligiblePlan_isNil() {
        #expect(makeSUT().externalPurchaseTitle(for: plan(apiPrice: nil)) == nil)
        #expect(makeSUT().externalPurchaseTitle(for: plan(introductoryOffer: offer())) == nil)
    }

    // MARK: - SUT

    private func makeSUT() -> ExternalPurchasePresenter {
        ExternalPurchasePresenter()
    }

    // MARK: - Fixtures

    private func plan(
        _ type: AccountTypeEntity = .proI,
        cycle: SubscriptionCycleEntity = .yearly,
        apiPrice: PlanPriceEntity? = PlanPriceEntity(price: 9, formattedPrice: "$9.00", currency: "USD"),
        introductoryOffer: SubscriptionOfferEntity? = nil,
        promotionalOffer: SubscriptionOfferEntity? = nil,
        mobileOffer: MobileOfferEntity? = nil
    ) -> PlanEntity {
        PlanEntity(
            productIdentifier: "pro1.oneYear",
            type: type,
            subscriptionCycle: cycle,
            apiPrice: apiPrice,
            appStorePrice: PlanPriceEntity(price: 10, formattedPrice: "$10.00", currency: "USD"),
            introductoryOffer: introductoryOffer,
            mobileOffer: mobileOffer,
            promotionalOffer: promotionalOffer
        )
    }

    private func offer() -> SubscriptionOfferEntity {
        SubscriptionOfferEntity(
            price: 5,
            period: .init(unit: .month, value: 1),
            periodCount: 1,
            paymentMode: .payAsYouGo
        )
    }

    private func signedMobileOffer() -> MobileOfferEntity {
        MobileOfferEntity(
            id: "promo",
            useAsTitle: false,
            label: nil,
            discountPercentage: 50,
            flags: 0,
            reshowTimeout: nil,
            expiryDate: nil,
            iosOfferId: "promo",
            iosSignature: MobileOfferIosSignatureEntity(
                offerId: "promo",
                keyId: "key",
                nonce: "nonce",
                timestamp: 0,
                signature: "sig"
            )
        )
    }
}
