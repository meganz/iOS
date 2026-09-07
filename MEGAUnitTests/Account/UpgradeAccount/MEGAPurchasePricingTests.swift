@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomainMock
import MEGARepo
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

    /// The expiry is what stops a lapsed campaign from being applied later, so it has to survive the lookup.
    @Test("reads the expiry of an offer that carries one")
    func mobileOffer_forAnOfferWithAnExpiry_readsItsExpiryDate() {
        let sut = makeSUT(pricingProducts: [
            MockPricingProduct(
                iOSID: "pro1.oneMonth",
                mobileOffer: MockMobileOffer(id: "black-friday", expiryTimestamp: 1_700_000_000)
            )
        ])

        let expiryDate = sut.mobileOffer(for: MockSKProduct(identifier: "pro1.oneMonth"))?.expiryDate

        #expect(expiryDate == Date(timeIntervalSince1970: 1_700_000_000))
    }

    @Test("reads no expiry for an offer that carries none")
    func mobileOffer_forAnOfferWithoutAnExpiry_isNil() {
        let sut = makeSUT(pricingProducts: [
            MockPricingProduct(iOSID: "pro1.oneMonth", mobileOffer: MockMobileOffer(id: "black-friday"))
        ])

        #expect(sut.mobileOffer(for: MockSKProduct(identifier: "pro1.oneMonth"))?.expiryDate == nil)
    }
}

/// Covers the two decisions `MEGAPurchase` makes before a payment reaches StoreKit: whether a promotional
/// offer should be attached at all, and what the resolution does when the App Store tells it nothing.
@Suite("MEGAPurchase promotional offer gate")
struct MEGAPurchasePromotionalOfferTests {

    // MARK: - shouldApplyPromotionalOffer(forProduct:eligibility:)

    /// Reading the customer's redeemability walks their whole transaction history, so a product that
    /// carries no offer must not pay for it.
    @Test("takes the normal path, without asking StoreKit, for a product carrying no offer")
    func shouldApplyPromotionalOffer_forAProductWithoutAnOffer_isFalseWithoutAskingStoreKit() async {
        let sut = makeSUT(pricingIdentifiers: ["pro1.oneMonth"])
        let eligibility = MockStoreKitSubscriptionEligibility(canRedeemPromotionalOffer: true)

        let shouldApply = await sut.shouldApplyPromotionalOffer(
            forProduct: MockSKProduct(identifier: "pro1.oneMonth"),
            eligibility: eligibility
        )

        #expect(shouldApply == false)
        #expect(eligibility.canRedeemPromotionalOfferCalled == 0)
    }

    /// An introductory offer carries no signature, so it must not send the purchase down the promotional
    /// path where a signature is what gets attached.
    @Test("takes the normal path for an offer that carries no signature")
    func shouldApplyPromotionalOffer_forAnUnsignedOffer_isFalse() async {
        let sut = makeSUT(pricingProducts: [
            MockPricingProduct(iOSID: "pro1.oneMonth", mobileOffer: MockMobileOffer(id: "intro-offer"))
        ])
        let eligibility = MockStoreKitSubscriptionEligibility(canRedeemPromotionalOffer: true)

        let shouldApply = await sut.shouldApplyPromotionalOffer(
            forProduct: MockSKProduct(identifier: "pro1.oneMonth"),
            eligibility: eligibility
        )

        #expect(shouldApply == false)
        #expect(eligibility.canRedeemPromotionalOfferCalled == 0)
    }

    @Test("takes the normal path for a product the pricing does not list")
    func shouldApplyPromotionalOffer_forAProductMissingFromThePricing_isFalse() async {
        let sut = makeSUT(pricingIdentifiers: ["pro1.oneMonth"])
        let eligibility = MockStoreKitSubscriptionEligibility(canRedeemPromotionalOffer: true)

        let shouldApply = await sut.shouldApplyPromotionalOffer(
            forProduct: MockSKProduct(identifier: "pro3.oneMonth"),
            eligibility: eligibility
        )

        #expect(shouldApply == false)
        #expect(eligibility.canRedeemPromotionalOfferCalled == 0)
    }

    /// Only a subscriber whose subscription Apple never revoked can redeem a promotional offer. Everyone
    /// else was shown the plan's normal price and buys at it, rather than being turned away at checkout.
    @Test("takes the normal path when the customer cannot redeem a promotional offer")
    func shouldApplyPromotionalOffer_whenTheCustomerCannotRedeem_isFalse() async {
        let sut = makeSUT(pricingProducts: [signedOfferProduct])
        let eligibility = MockStoreKitSubscriptionEligibility(canRedeemPromotionalOffer: false)

        let shouldApply = await sut.shouldApplyPromotionalOffer(
            forProduct: MockSKProduct(identifier: "pro1.oneMonth"),
            eligibility: eligibility
        )

        #expect(shouldApply == false)
        #expect(eligibility.canRedeemPromotionalOfferCalled == 1)
    }

    @Test("takes the promotional path for a signed offer and a customer who can redeem it")
    func shouldApplyPromotionalOffer_forASignedOfferAndARedeemingCustomer_isTrue() async {
        let sut = makeSUT(pricingProducts: [signedOfferProduct])
        let eligibility = MockStoreKitSubscriptionEligibility(canRedeemPromotionalOffer: true)

        let shouldApply = await sut.shouldApplyPromotionalOffer(
            forProduct: MockSKProduct(identifier: "pro1.oneMonth"),
            eligibility: eligibility
        )

        #expect(shouldApply)
        #expect(eligibility.canRedeemPromotionalOfferCalled == 1)
    }

    /// A lapsed campaign is rejected further in, by the resolution, which abandons the purchase loudly. The
    /// gate deliberately lets it through rather than quietly charging the full price of a discounted card.
    @Test("takes the promotional path even for an offer whose campaign has lapsed")
    func shouldApplyPromotionalOffer_forAnExpiredOffer_isTrue() async {
        let sut = makeSUT(pricingProducts: [
            MockPricingProduct(
                iOSID: "pro1.oneMonth",
                mobileOffer: MockMobileOffer(
                    id: "black-friday",
                    expiryTimestamp: 1,
                    iosSignature: MockMobileOfferIosSignature()
                )
            )
        ])
        let eligibility = MockStoreKitSubscriptionEligibility(canRedeemPromotionalOffer: true)

        let shouldApply = await sut.shouldApplyPromotionalOffer(
            forProduct: MockSKProduct(identifier: "pro1.oneMonth"),
            eligibility: eligibility
        )

        #expect(shouldApply)
    }

    // MARK: - promotionalOffer(forProduct:eligibility:subscriptionInfoProvider:requester:)

    /// The lookup swallows its errors, so an unreachable App Store and an unknown product arrive the same
    /// way. Neither can confirm the advertised discount, so the purchase is abandoned rather than charged
    /// at full price.
    @Test("abandons the purchase when the App Store returns no subscription information")
    func promotionalOffer_withoutSubscriptionInformation_throwsSubscriptionInfoNotAvailable() async {
        let sut = makeSUT(pricingProducts: [signedOfferProduct])
        let requester = MockPricingRequester()

        do {
            _ = try await sut.promotionalOffer(
                forProduct: MockSKProduct(identifier: "pro1.oneMonth"),
                eligibility: MockStoreKitSubscriptionEligibility(canRedeemPromotionalOffer: true),
                subscriptionInfoProvider: MockStoreKitSubscriptionInfoProvider(),
                requester: requester
            )
            Issue.record("Expected the resolution to abandon the purchase")
        } catch {
            guard case .subscriptionInfoNotAvailable = error else {
                Issue.record("Expected .subscriptionInfoNotAvailable, got \(error)")
                return
            }
        }

        // The signature is only re-signed once a promotional offer is still in play.
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

private var signedOfferProduct: MockPricingProduct {
    MockPricingProduct(
        iOSID: "pro1.oneMonth",
        mobileOffer: MockMobileOffer(id: "black-friday", iosSignature: MockMobileOfferIosSignature())
    )
}

private final class MockStoreKitSubscriptionEligibility: StoreKitSubscriptionEligibilityChecking, @unchecked Sendable {
    private let canRedeem: Bool
    private(set) var canRedeemPromotionalOfferCalled = 0

    init(canRedeemPromotionalOffer: Bool) {
        canRedeem = canRedeemPromotionalOffer
    }

    func canRedeemPromotionalOffer() async -> Bool {
        canRedeemPromotionalOfferCalled += 1
        return canRedeem
    }

    func activeSubscriptionGroupIDs() async -> Set<String> { [] }

    func isIntroductoryOfferRedeemable(
        for subscription: Product.SubscriptionInfo,
        activeGroupIDs: Set<String>
    ) async -> Bool {
        false
    }
}

/// `Product.SubscriptionInfo` has no public initialiser, so a stub can only report the App Store saying
/// nothing. The paths that need a real one stay out of reach until the lookup returns plain values.
private struct MockStoreKitSubscriptionInfoProvider: StoreKitSubscriptionInfoProviding {
    func subscriptionInfo(forProductIdentifier productIdentifier: String) async -> Product.SubscriptionInfo? {
        nil
    }
}
