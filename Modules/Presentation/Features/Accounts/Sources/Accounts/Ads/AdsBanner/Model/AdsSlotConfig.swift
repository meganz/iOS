import MEGADomain

public struct AdsSlotConfig: Equatable, Sendable {
    let adsSlot: AdsSlotEntity
    let displayAds: Bool
    
    public init(
        adsSlot: AdsSlotEntity,
        displayAds: Bool
    ) {
        self.adsSlot = adsSlot
        self.displayAds = displayAds
    }
    
    public static func == (lhs: AdsSlotConfig, rhs: AdsSlotConfig) -> Bool {
        lhs.adsSlot == rhs.adsSlot && lhs.displayAds == rhs.displayAds
    }
}
