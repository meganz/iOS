import Foundation

/// Signed StoreKit promotional-offer payload for an iOS mobile offer.
/// required to redeem a signed App Store promotional offer via `SKPaymentDiscount` (or StoreKit 2's `PurchaseOption.promotionalOffer`).
public struct MobileOfferIosSignatureEntity: Sendable, Equatable {
    public let offerId: String
    public let keyId: String
    public let nonce: String
    public let timestamp: Int64
    public let signature: String

    public init(
        offerId: String,
        keyId: String,
        nonce: String,
        timestamp: Int64,
        signature: String
    ) {
        self.offerId = offerId
        self.keyId = keyId
        self.nonce = nonce
        self.timestamp = timestamp
        self.signature = signature
    }
}

/// An API-driven mobile offer attached to a purchasable plan.
/// Could represent either intro or promo offer. If `iosSignature` is present, it's a promo offer.
/// Sourced from the API `utqa` command's `mo` object and surfaced through the SDK.
/// Note:
///     For each campaign, all the MobileOfferEntity will share common values of`reshowTimeout` and `expiryDate` and `flags`
///     even though these properites are per-offer.
public struct MobileOfferEntity: Sendable, Equatable {
    /// The offer identifier, e.g. `black-friday-2025`.
    public let id: String

    /// Whether the offer label should be used as the title. This value is used by both Introductory offers and Promotional offers.
    public let useAsTitle: Bool

    /// Localized campaign label to display, or `nil` when not provided. This value is used by both Introductory offers and Promotional offers.
    public let label: String?

    /// Discount percentage to display to the customer (0 when not provided). Only used for promotional offers.
    public let discountPercentage: Int

    /// Client feature-flag bitmask (always present, normally 0).
    /// Usage:
    /// - Bit 1: Used to determine whether an offer can be advertised (e.g: Show as a promoted plan at app launch) see [IOS-12376]
    /// - Other bit: Reserved for future use.
    public let flags: Int

    /// How long before the offer may be reshown, or `nil` when not provided.
    public let reshowTimeout: TimeInterval?

    /// When the offer expires, or `nil` when not provided. This value is used by both Introductory offers and Promotional offers.
    public let expiryDate: Date?

    /// Store offer identifier for iOS clients, or `nil` when not provided.
    public let iosOfferId: String?

    /// Signed StoreKit payload for redeeming the offer, or `nil` when not provided. Only used for promotional offers.
    public let iosSignature: MobileOfferIosSignatureEntity?

    /// Identifies the campaign this offer belongs to, or `0` when it belongs to no campaign.
    /// Note: In practice an offer will always carry a non-zero campaignId.
    public let campaignId: UInt64

    public init(
        id: String,
        useAsTitle: Bool,
        label: String?,
        discountPercentage: Int,
        flags: Int,
        reshowTimeout: TimeInterval?,
        expiryDate: Date?,
        iosOfferId: String?,
        iosSignature: MobileOfferIosSignatureEntity?,
        campaignId: UInt64 = 0
    ) {
        self.id = id
        self.useAsTitle = useAsTitle
        self.label = label
        self.discountPercentage = discountPercentage
        self.flags = flags
        self.reshowTimeout = reshowTimeout
        self.expiryDate = expiryDate
        self.iosOfferId = iosOfferId
        self.iosSignature = iosSignature
        self.campaignId = campaignId
    }
}
