import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class MEGAPricingAdditionsTests: XCTestCase {
    private let proPlans = [MockPricingProduct(proLevel: .lite, storageGB: 400),
                            MockPricingProduct(proLevel: .proI, storageGB: 2048),
                            MockPricingProduct(proLevel: .proII, storageGB: 8192),
                            MockPricingProduct(proLevel: .proIII, storageGB: 16384)]
    
    private var randomProPlan: MockPricingProduct {
        proPlans.randomElement() ?? MockPricingProduct(proLevel: .proIII, storageGB: 16384)
    }
    
    private var randomAccountType: AccountTypeEntity {
        let types: [AccountTypeEntity] = [.lite, .proI, .proII, .proIII]
        return types.randomElement() ?? .proIII
    }
    
    func testProductStorageOfAccountType_noProducts_shouldReturnZero() {
        let pricing = MockMEGAPricing(productList: nil)
        let storageGB = pricing.productStorageGB(ofAccountType: randomAccountType)
        XCTAssertEqual(storageGB, 0)
    }
    
    func testProductStorageOfAccountType_withEmptyProducts_shouldReturnZero() {
        let pricing = MockMEGAPricing(productList: [])
        let storageGB = pricing.productStorageGB(ofAccountType: randomAccountType)
        XCTAssertEqual(storageGB, 0)
    }
    
    func testProductStorageOfAccountType_withValidProducts_shouldReturnCorrectValue() {
        let expectedProPlan = randomProPlan

        let pricing = MockMEGAPricing(productList: proPlans)
        let storageGB = pricing.productStorageGB(ofAccountType: expectedProPlan.proLevel.toAccountTypeEntity())

        XCTAssertEqual(storageGB, expectedProPlan.storageGB)
    }

    // MARK: - Mobile offers

    func testToMobileOfferEntity_productWithoutAnOffer_shouldReturnNil() {
        let pricing = MockMEGAPricing(productList: [MockPricingProduct(proLevel: .proI)])

        XCTAssertNil(pricing.toMobileOfferEntity(index: 0))
    }

    func testToMobileOfferEntity_productWithAnOffer_shouldMapTheCampaignId() {
        let pricing = MockMEGAPricing(productList: [
            MockPricingProduct(proLevel: .proI, mobileOffer: MockMobileOffer(id: "black-friday", campaignId: 2026))
        ])

        XCTAssertEqual(pricing.toMobileOfferEntity(index: 0)?.campaignId, 2026)
    }

    func testToMobileOfferEntity_offerWithoutACampaign_shouldMapZeroCampaignId() {
        let pricing = MockMEGAPricing(productList: [
            MockPricingProduct(proLevel: .proI, mobileOffer: MockMobileOffer(id: "black-friday", campaignId: 0))
        ])

        XCTAssertEqual(pricing.toMobileOfferEntity(index: 0)?.campaignId, 0)
    }

    /// An offer the API did not sign is an introductory offer, and carrying no signature is how the
    /// purchase flow tells the two apart.
    func testToMobileOfferEntity_offerWithoutAnIosPayload_shouldMapNoSignature() {
        let pricing = MockMEGAPricing(productList: [
            MockPricingProduct(proLevel: .proI, mobileOffer: MockMobileOffer(id: "black-friday"))
        ])

        XCTAssertNil(pricing.toMobileOfferEntity(index: 0)?.iosSignature)
    }

    /// Every field of the signed payload reaches StoreKit as-is: a mismatched one makes the App Store
    /// reject the discount.
    func testToMobileOfferEntity_offerWithAnIosPayload_shouldMapTheWholeSignature() {
        let pricing = MockMEGAPricing(productList: [
            MockPricingProduct(
                proLevel: .proI,
                mobileOffer: MockMobileOffer(
                    id: "black-friday",
                    iosSignature: MockMobileOfferIosSignature(
                        offerId: "promo-1",
                        keyId: "key-1",
                        nonce: "5f5b4a3e-9d0e-4c5a-8f2b-1a2b3c4d5e6f",
                        timestampMs: 1_700_000_000_000,
                        signature: "signed-payload"
                    )
                )
            )
        ])

        XCTAssertEqual(
            pricing.toMobileOfferEntity(index: 0)?.iosSignature,
            MobileOfferIosSignatureEntity(
                offerId: "promo-1",
                keyId: "key-1",
                nonce: "5f5b4a3e-9d0e-4c5a-8f2b-1a2b3c4d5e6f",
                timestamp: 1_700_000_000_000,
                signature: "signed-payload"
            )
        )
    }

    func testToMobileOfferEntity_offerWithAnIosPayload_shouldMapItsOfferId() {
        let pricing = MockMEGAPricing(productList: [
            MockPricingProduct(
                proLevel: .proI,
                mobileOffer: MockMobileOffer(id: "black-friday", iosSignature: MockMobileOfferIosSignature(offerId: "promo-1"))
            )
        ])

        XCTAssertEqual(pricing.toMobileOfferEntity(index: 0)?.iosOfferId, "promo-1")
    }
}
