import MEGAAppSDKRepoMock
import MEGADomainMock
@testable import MEGA
import StoreKit
import Testing

/// Covers how `MEGAPurchase` resolves an `SKProduct` against `MEGAPricing`.
///
/// The App Store catalogue and the API catalogue are two independent lists that merely overlap: a plan
/// can exist in one and not the other, and nothing keeps their order in sync. Every lookup here is
/// therefore resolved against `pricing` itself rather than against a separately cached list of
/// identifiers, which is what these tests pin down.
@Suite("MEGAPurchase pricing lookups")
struct MEGAPurchasePricingTests {

    // MARK: - productIndex(for:)

    @Test("resolves nothing while no pricing has been loaded")
    func productIndex_withoutPricing_isNil() {
        // A bare `MEGAPurchase` rather than the mock, which always carries a pricing.
        let sut = MEGAPurchase()

        #expect(sut.productIndex(for: MockSKProduct(identifier: "pro1.oneMonth")) == nil)
    }

    @Test("resolves a product to the pricing entry carrying its identifier")
    func productIndex_forAProductInThePricing_isItsPricingIndex() {
        let sut = makeSUT(pricingIdentifiers: ["pro1.oneMonth", "pro2.oneMonth", "pro3.oneMonth"])

        #expect(sut.productIndex(for: MockSKProduct(identifier: "pro2.oneMonth")) == 1)
    }

    /// The reason the index is resolved against `pricing` at all: the App Store lists the products in
    /// its own order, so the position a product occupies elsewhere says nothing about its pricing index.
    @Test("resolves against the pricing order rather than the order the App Store returned")
    func productIndex_whenTheStoreOrderDiffers_stillUsesThePricingOrder() {
        let sut = makeSUT(pricingIdentifiers: ["pro3.oneMonth", "pro1.oneMonth", "pro2.oneMonth"])

        #expect(sut.productIndex(for: MockSKProduct(identifier: "pro1.oneMonth")) == 1)
        #expect(sut.productIndex(for: MockSKProduct(identifier: "pro3.oneMonth")) == 0)
    }

    /// A product the App Store sells but the API does not price — the mismatch the repository has to
    /// skip rather than read a plan at some arbitrary index.
    @Test("resolves nothing for a product the pricing does not list")
    func productIndex_forAProductMissingFromThePricing_isNil() {
        let sut = makeSUT(pricingIdentifiers: ["pro1.oneMonth", "pro2.oneMonth"])

        #expect(sut.productIndex(for: MockSKProduct(identifier: "pro3.oneMonth")) == nil)
    }

    /// A plan the API prices before it exists in App Store Connect carries no iOS identifier at all, and
    /// must not be matched by anything.
    @Test("skips pricing entries that carry no iOS identifier")
    func productIndex_whenAPricingEntryHasNoIOSIdentifier_skipsIt() {
        let sut = makeSUT(pricingIdentifiers: [nil, "pro1.oneMonth"])

        #expect(sut.productIndex(for: MockSKProduct(identifier: "pro1.oneMonth")) == 1)
    }

    // MARK: - mobileOffer(for:)

    @Test("reads no offer while no pricing has been loaded")
    func mobileOffer_withoutPricing_isNil() {
        let sut = MEGAPurchase()

        #expect(sut.mobileOffer(for: MockSKProduct(identifier: "pro1.oneMonth")) == nil)
    }

    @Test("reads no offer for a product the pricing does not list")
    func mobileOffer_forAProductMissingFromThePricing_isNil() {
        let sut = makeSUT(pricingProducts: [
            MockPricingProduct(iOSID: "pro1.oneMonth", mobileOffer: MockMobileOffer(id: "black-friday"))
        ])

        #expect(sut.mobileOffer(for: MockSKProduct(identifier: "pro2.oneMonth")) == nil)
    }

    @Test("reads no offer for a priced product that carries none")
    func mobileOffer_forAProductWithoutAnOffer_isNil() {
        let sut = makeSUT(pricingIdentifiers: ["pro1.oneMonth"])

        #expect(sut.mobileOffer(for: MockSKProduct(identifier: "pro1.oneMonth")) == nil)
    }

    /// Reading the offer at the wrong index is how a plan ends up advertising a campaign that belongs to
    /// a different plan, so this asserts the offer comes from the entry that actually matches.
    @Test("reads the offer of the matching pricing entry, not of another entry")
    func mobileOffer_readsTheOfferOfTheMatchingEntry() {
        let sut = makeSUT(pricingProducts: [
            MockPricingProduct(iOSID: "pro1.oneMonth", mobileOffer: MockMobileOffer(id: "pro1-offer")),
            MockPricingProduct(iOSID: "pro2.oneMonth", mobileOffer: MockMobileOffer(id: "pro2-offer"))
        ])

        #expect(sut.mobileOffer(for: MockSKProduct(identifier: "pro2.oneMonth"))?.id == "pro2-offer")
    }

    @Test("reads the signed payload of a promotional offer")
    func mobileOffer_forAPromotionalOffer_readsItsSignature() {
        let sut = makeSUT(pricingProducts: [
            MockPricingProduct(
                iOSID: "pro1.oneMonth",
                mobileOffer: MockMobileOffer(id: "black-friday", iosSignature: MockMobileOfferIosSignature(offerId: "promo-1"))
            )
        ])

        #expect(sut.mobileOffer(for: MockSKProduct(identifier: "pro1.oneMonth"))?.iosSignature?.offerId == "promo-1")
    }

    // MARK: - refreshPricing(forProduct:)

    /// A signature is only valid for about a day, so a product carrying one is always re-signed before it
    /// reaches the payment queue.
    @Test("refreshes the pricing before purchasing a product that carries a promotional offer")
    func refreshPricing_forAPromotionalOffer_refreshesAndSucceeds() async {
        let sut = makeSUT(pricingProducts: [
            MockPricingProduct(iOSID: "pro1.oneMonth", mobileOffer: MockMobileOffer(id: "black-friday", iosSignature: MockMobileOfferIosSignature()))
        ])
        let requester = MockPricingRequester()

        let refreshed = await sut.refreshPricing(forProduct: MockSKProduct(identifier: "pro1.oneMonth"), requester: requester)

        #expect(refreshed)
        #expect(requester.refreshPricingCalled == 1)
    }

    /// Reporting the failure is what makes the caller fall back to purchasing without the discount rather
    /// than sending StoreKit a signature that may no longer be valid.
    @Test("reports a failed refresh")
    func refreshPricing_whenTheRefreshFails_reportsIt() async {
        let sut = makeSUT(pricingProducts: [
            MockPricingProduct(iOSID: "pro1.oneMonth", mobileOffer: MockMobileOffer(id: "black-friday", iosSignature: MockMobileOfferIosSignature()))
        ])
        let requester = MockPricingRequester(result: .failure(CancellationError()))

        let refreshed = await sut.refreshPricing(forProduct: MockSKProduct(identifier: "pro1.oneMonth"), requester: requester)

        #expect(refreshed == false)
        #expect(requester.refreshPricingCalled == 1)
    }

    /// Nothing needs re-signing here, so spending a pricing request before every ordinary purchase would
    /// only delay the payment sheet.
    @Test("purchases without a refresh when the product carries no promotional offer")
    func refreshPricing_withoutAPromotionalOffer_doesNotRefresh() async {
        let sut = makeSUT(pricingProducts: [
            MockPricingProduct(iOSID: "pro1.oneMonth"),
            MockPricingProduct(iOSID: "pro2.oneMonth", mobileOffer: MockMobileOffer(id: "intro-offer"))
        ])
        let requester = MockPricingRequester()

        // A plan with no offer at all, and a plan whose offer is introductory rather than promotional:
        // neither carries a signature, so neither has anything to re-sign.
        let refreshedForPlanWithoutAnOffer = await sut.refreshPricing(forProduct: MockSKProduct(identifier: "pro1.oneMonth"), requester: requester)
        let refreshedForIntroOffer = await sut.refreshPricing(forProduct: MockSKProduct(identifier: "pro2.oneMonth"), requester: requester)

        #expect(refreshedForPlanWithoutAnOffer)
        #expect(refreshedForIntroOffer)
        #expect(requester.refreshPricingCalled == 0)
    }

    @Test("purchases without a refresh when the product is not in the pricing")
    func refreshPricing_forAProductMissingFromThePricing_doesNotRefresh() async {
        let sut = makeSUT(pricingIdentifiers: ["pro1.oneMonth"])
        let requester = MockPricingRequester()

        let refreshed = await sut.refreshPricing(forProduct: MockSKProduct(identifier: "pro3.oneMonth"), requester: requester)

        #expect(refreshed)
        #expect(requester.refreshPricingCalled == 0)
    }
}

// MARK: - Helpers

private func makeSUT(pricingProducts: [MockPricingProduct]) -> MEGAPurchase {
    let purchase = MockMEGAPurchase()
    purchase.pricing = MockMEGAPricing(productList: pricingProducts)
    return purchase
}

private func makeSUT(pricingIdentifiers: [String?]) -> MEGAPurchase {
    makeSUT(pricingProducts: pricingIdentifiers.map { MockPricingProduct(iOSID: $0) })
}

private extension MockSKProduct {
    /// Only the identifier matters to a pricing lookup; the price is there because `SKProduct` has one.
    convenience init(identifier: String) {
        self.init(identifier: identifier, price: "1", priceLocale: Locale(identifier: "en_US"))
    }
}
