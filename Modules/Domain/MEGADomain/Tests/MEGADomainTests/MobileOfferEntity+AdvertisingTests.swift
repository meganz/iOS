import Foundation
import MEGADomain
import Testing

/// `isAdvertisable` reads bit 0 of the API's `mo.f` bitmask. The bit is a strict opt-in, and the surrounding
/// bits carry unrelated meanings the client does not interpret — so the two failure modes worth pinning are
/// treating a non-zero mask as advertisable, and letting a neighbouring bit switch the opt-in off.
@Suite("MobileOfferEntity.isAdvertisable")
struct MobileOfferEntityAdvertisingTests {

    @Test("An empty bitmask is not advertisable")
    func isAdvertisable_noFlags_isFalse() {
        #expect(offer(flags: 0).isAdvertisable == false)
    }

    @Test("Bit 0 alone is advertisable")
    func isAdvertisable_onlyBitZero_isTrue() {
        #expect(offer(flags: 1).isAdvertisable)
    }

    @Test("Bit 0 stays the opt-in however many other bits the API sets", arguments: [0b11, 0b101, 0b1111_1111])
    func isAdvertisable_bitZeroAlongsideOthers_isTrue(flags: Int) {
        #expect(offer(flags: flags).isAdvertisable)
    }

    /// The mistake this guards against is `flags != 0`: every one of these masks is truthy, and none of them
    /// opts the campaign in.
    @Test("Other bits without bit 0 are not advertisable", arguments: [0b10, 0b100, 0b1111_1110])
    func isAdvertisable_bitsWithoutBitZero_isFalse(flags: Int) {
        #expect(offer(flags: flags).isAdvertisable == false)
    }

    // MARK: - Helpers

    private func offer(flags: Int) -> MobileOfferEntity {
        MobileOfferEntity(
            id: "black-friday",
            useAsTitle: false,
            label: nil,
            discountPercentage: 50,
            flags: flags,
            reshowTimeout: nil,
            expiryDate: nil,
            iosOfferId: nil,
            iosSignature: nil,
            campaignId: 2026
        )
    }
}
