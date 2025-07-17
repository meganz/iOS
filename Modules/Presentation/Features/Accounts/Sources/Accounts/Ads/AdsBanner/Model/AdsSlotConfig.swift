import MEGADomain

public struct AdsSlotConfig: Equatable, Sendable {
    let displayAds: Bool
    
    public init(
        displayAds: Bool
    ) {
        self.displayAds = displayAds
    }
    
    public static func == (lhs: AdsSlotConfig, rhs: AdsSlotConfig) -> Bool {
        lhs.displayAds == rhs.displayAds
    }
}
