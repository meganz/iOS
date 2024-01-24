import MEGADomain

public struct AdsSlotConfig: Equatable {
    let adsSlot: AdsSlotEntity
    let displayAds: Bool
    let isAdsCookieEnabled: () async -> Bool
    
    public init(
        adsSlot: AdsSlotEntity,
        displayAds: Bool,
        isAdsCookieEnabled: @escaping () async -> Bool
    ) {
        self.adsSlot = adsSlot
        self.displayAds = displayAds
        self.isAdsCookieEnabled = isAdsCookieEnabled
    }
    
    public static func == (lhs: AdsSlotConfig, rhs: AdsSlotConfig) -> Bool {
        lhs.adsSlot == rhs.adsSlot && lhs.displayAds == rhs.displayAds
    }
}
