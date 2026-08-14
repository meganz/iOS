import MEGAAppSDKRepo
import MEGADomain
import MEGASdk

public struct MockPricingProduct {
    public var handle: HandleEntity
    public var proLevel: MEGAAccountType
    public var storageGB: Int
    public var transferGB: Int
    public var months: Int
    public var amount: Int
    public var localPrice: Int
    public var description: String?
    public var iOSID: String?
    public var mobileOffer: MockMobileOffer?

    public init(handle: HandleEntity = .invalidHandle,
                proLevel: MEGAAccountType = .free,
                storageGB: Int = 0,
                transferGB: Int = 0,
                months: Int = 0,
                amount: Int = 0,
                localPrice: Int = 0,
                description: String? = nil,
                iOSID: String? = nil,
                mobileOffer: MockMobileOffer? = nil) {
        self.handle = handle
        self.proLevel = proLevel
        self.storageGB = storageGB
        self.transferGB = transferGB
        self.months = months
        self.amount = amount
        self.localPrice = localPrice
        self.description = description
        self.iOSID = iOSID
        self.mobileOffer = mobileOffer
    }
}

/// The `mo` object the API attaches to a product, as much of it as the entity mapping reads.
/// A product carrying one reports `hasMobileOffers` — its absence is how a product without an offer is expressed.
public struct MockMobileOffer {
    public var id: String
    public var useAsTitle: Bool
    public var label: String?
    public var discountPercentage: Int32
    public var flags: UInt32
    public var reshowInterval: Int64
    public var expiryTimestamp: Int64
    public var campaignId: UInt64
    /// An offer carrying one is a promotional offer; without it the offer is an introductory one.
    public var iosSignature: MockMobileOfferIosSignature?

    public init(id: String = "",
                useAsTitle: Bool = false,
                label: String? = nil,
                discountPercentage: Int32 = 0,
                flags: UInt32 = 0,
                reshowInterval: Int64 = 0,
                expiryTimestamp: Int64 = 0,
                campaignId: UInt64 = 0,
                iosSignature: MockMobileOfferIosSignature? = nil) {
        self.id = id
        self.useAsTitle = useAsTitle
        self.label = label
        self.discountPercentage = discountPercentage
        self.flags = flags
        self.reshowInterval = reshowInterval
        self.expiryTimestamp = expiryTimestamp
        self.campaignId = campaignId
        self.iosSignature = iosSignature
    }
}

/// The signed StoreKit payload the API attaches to a promotional offer. Its presence is what
/// `hasMobileOfferIos` reports, so a mocked offer without one maps to an intro offer.
public struct MockMobileOfferIosSignature {
    public var offerId: String
    public var keyId: String
    public var nonce: String
    public var timestampMs: Int64
    public var signature: String

    public init(offerId: String = "promo-offer",
                keyId: String = "key-id",
                nonce: String = "5f5b4a3e-9d0e-4c5a-8f2b-1a2b3c4d5e6f",
                timestampMs: Int64 = 1_700_000_000_000,
                signature: String = "signature") {
        self.offerId = offerId
        self.keyId = keyId
        self.nonce = nonce
        self.timestampMs = timestampMs
        self.signature = signature
    }
}

public final class MockMEGAPricing: MEGAPricing {
    private let productList: [MockPricingProduct]?
    
    public init(productList: [MockPricingProduct]?) {
        self.productList = productList
    }
    
    public override var products: Int {
        productList?.count ?? 0
    }

    private func product(at index: Int) -> MockPricingProduct? {
        productList?[safe: index]
    }
    
    public override func handle(atProductIndex index: Int) -> UInt64 {
        product(at: index)?.handle ?? .invalidHandle
    }
    
    public override func proLevel(atProductIndex index: Int) -> MEGAAccountType {
        product(at: index)?.proLevel ?? .free
    }
    
    public override func storageGB(atProductIndex index: Int) -> Int {
        product(at: index)?.storageGB ?? 0
    }
    
    public override func transferGB(atProductIndex index: Int) -> Int {
        product(at: index)?.transferGB ?? 0
    }
    
    public override func months(atProductIndex index: Int) -> Int {
        product(at: index)?.months ?? 0
    }
    
    public override func amount(atProductIndex index: Int) -> Int {
        product(at: index)?.amount ?? 0
    }
    
    public override func localPrice(atProductIndex index: Int) -> Int {
        product(at: index)?.localPrice ?? 0
    }
    
    public override func description(atProductIndex index: Int) -> String? {
        product(at: index)?.description
    }
    
    public override func iOSID(atProductIndex index: Int) -> String? {
        product(at: index)?.iOSID
    }

    // MARK: - Mobile offers

    public override func hasMobileOffers(atProductIndex index: Int) -> Bool {
        mobileOffer(at: index) != nil
    }

    public override func mobileOfferId(atProductIndex index: Int) -> String? {
        mobileOffer(at: index)?.id
    }

    public override func hasMobileOfferUat(atProductIndex index: Int) -> Bool {
        mobileOffer(at: index)?.useAsTitle ?? false
    }

    public override func mobileOfferLabel(atProductIndex index: Int) -> String? {
        mobileOffer(at: index)?.label
    }

    public override func mobileOfferDiscountPercentage(atProductIndex index: Int) -> Int32 {
        mobileOffer(at: index)?.discountPercentage ?? 0
    }

    public override func mobileOfferFlags(atProductIndex index: Int) -> UInt32 {
        mobileOffer(at: index)?.flags ?? 0
    }

    public override func mobileOfferReshowInterval(atProductIndex index: Int) -> Int64 {
        mobileOffer(at: index)?.reshowInterval ?? 0
    }

    public override func mobileOfferExpiryTimestamp(atProductIndex index: Int) -> Int64 {
        mobileOffer(at: index)?.expiryTimestamp ?? 0
    }

    public override func mobileOfferCampaignId(atProductIndex index: Int) -> UInt64 {
        mobileOffer(at: index)?.campaignId ?? 0
    }

    /// An offer only reports an iOS payload once one is mocked; without it the offer maps to an
    /// intro offer rather than a promotional one.
    public override func hasMobileOfferIos(atProductIndex index: Int) -> Bool {
        iosSignature(at: index) != nil
    }

    public override func mobileOfferIosOfferId(atProductIndex index: Int) -> String? {
        iosSignature(at: index)?.offerId
    }

    public override func mobileOfferIosKeyId(atProductIndex index: Int) -> String? {
        iosSignature(at: index)?.keyId
    }

    public override func mobileOfferIosNonce(atProductIndex index: Int) -> String? {
        iosSignature(at: index)?.nonce
    }

    public override func mobileOfferIosTimestampMs(atProductIndex index: Int) -> Int64 {
        iosSignature(at: index)?.timestampMs ?? 0
    }

    public override func mobileOfferIosSignature(atProductIndex index: Int) -> String? {
        iosSignature(at: index)?.signature
    }

    private func mobileOffer(at index: Int) -> MockMobileOffer? {
        product(at: index)?.mobileOffer
    }

    private func iosSignature(at index: Int) -> MockMobileOfferIosSignature? {
        mobileOffer(at: index)?.iosSignature
    }
}
