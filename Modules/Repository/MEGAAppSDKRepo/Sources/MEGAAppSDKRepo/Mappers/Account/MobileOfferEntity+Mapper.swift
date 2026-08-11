import Foundation
import MEGADomain
import MEGASdk

// MARK: - MEGAPricing
extension MEGAPricing {
    public func toMobileOfferEntity(index: Int) -> MobileOfferEntity? {
        guard hasMobileOffers(atProductIndex: index) else { return nil }

        let reshowInterval = mobileOfferReshowInterval(atProductIndex: index)
        let expiryTimestamp = mobileOfferExpiryTimestamp(atProductIndex: index)

        return MobileOfferEntity(
            id: mobileOfferId(atProductIndex: index) ?? "",
            useAsTitle: hasMobileOfferUat(atProductIndex: index),
            label: mobileOfferLabel(atProductIndex: index),
            discountPercentage: Int(mobileOfferDiscountPercentage(atProductIndex: index)),
            flags: Int(mobileOfferFlags(atProductIndex: index)),
            reshowTimeout: reshowInterval > 0 ? TimeInterval(reshowInterval) : nil,
            expiryDate: expiryTimestamp > 0 ? Date(timeIntervalSince1970: TimeInterval(expiryTimestamp)) : nil,
            iosOfferId: mobileOfferIosOfferId(atProductIndex: index),
            iosSignature: toMobileOfferIosSignatureEntity(index: index),
            campaignId: 0 // [IOS-12395] - Adopt campaignId from SDK
        )
    }

    private func toMobileOfferIosSignatureEntity(index: Int) -> MobileOfferIosSignatureEntity? {
        guard hasMobileOfferIos(atProductIndex: index) else { return nil }

        return MobileOfferIosSignatureEntity(
            offerId: mobileOfferIosOfferId(atProductIndex: index) ?? "",
            keyId: mobileOfferIosKeyId(atProductIndex: index) ?? "",
            nonce: mobileOfferIosNonce(atProductIndex: index) ?? "",
            timestamp: mobileOfferIosTimestampMs(atProductIndex: index),
            signature: mobileOfferIosSignature(atProductIndex: index) ?? ""
        )
    }
}
