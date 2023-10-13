import MEGADomain

public struct AdsSlotConfig: Equatable {
    let adsSlot: AdsSlotEntity
    let displayAds: Bool
    
    public init(adsSlot: AdsSlotEntity, displayAds: Bool) {
        self.adsSlot = adsSlot
        self.displayAds = displayAds
    }
}
