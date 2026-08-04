@testable import Accounts
import Foundation
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

    @Test("An eligible plan advertises how much cheaper the website is")
    func externalPurchaseTitle_withEligiblePlan_advertisesTheSaving() {
        #expect(makeSUT().externalPurchaseTitle(for: plan()) == expectedTitle("10%"))
    }

    @Test("An ineligible plan carries no title")
    func externalPurchaseTitle_withIneligiblePlan_isNil() {
        #expect(makeSUT().externalPurchaseTitle(for: plan(apiPrice: nil)) == nil)
        #expect(makeSUT().externalPurchaseTitle(for: plan(introductoryOffer: offer())) == nil)
    }

    // MARK: - Saving percentage

    @Test("A saving below the half percent is rounded down")
    func externalPurchaseTitle_withSavingBelowHalfPercent_roundsDown() {
        let sut = makeSUT()
        #expect(sut.externalPurchaseTitle(for: plan(apiPrice: price(7.77))) == expectedTitle("22%"))
    }

    @Test("A saving above the half percent is rounded up")
    func externalPurchaseTitle_withSavingAboveHalfPercent_roundsUp() {
        let sut = makeSUT()
        #expect(sut.externalPurchaseTitle(for: plan(apiPrice: price(7.73))) == expectedTitle("23%"))
    }

    @Test("Prices in different currencies fall back to the advertised saving")
    func externalPurchaseTitle_withMismatchedCurrencies_isTheAdvertisedSaving() {
        let sut = makeSUT()
        #expect(sut.externalPurchaseTitle(for: plan(apiPrice: price(9, currency: "EUR"))) == expectedTitle("15%"))
    }

    @Test("A website price that is not cheaper falls back to the advertised saving")
    func externalPurchaseTitle_withAPIPriceNotCheaper_isTheAdvertisedSaving() {
        let sut = makeSUT()
        #expect(sut.externalPurchaseTitle(for: plan(apiPrice: price(10))) == expectedTitle("15%"))
        #expect(sut.externalPurchaseTitle(for: plan(apiPrice: price(12))) == expectedTitle("15%"))
    }

    // MARK: - SUT

    private func makeSUT() -> ExternalPurchasePresenter {
        ExternalPurchasePresenter()
    }

    // MARK: - Fixtures

    private func expectedTitle(_ percentage: String) -> String {
        Strings.Localizable.SubscriptionPurchase.Revamp.Button.BuyOnWebsite.saveUpTo(percentage)
    }

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

    private func price(_ price: Decimal, currency: String = "USD") -> PlanPriceEntity {
        PlanPriceEntity(price: price, formattedPrice: "\(price)", currency: currency)
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
