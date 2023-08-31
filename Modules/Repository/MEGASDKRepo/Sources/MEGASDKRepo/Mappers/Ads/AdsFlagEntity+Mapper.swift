import MEGADomain
import MEGASdk

extension AdsFlagEntity {
    public func toAdsFlag() -> AdsFlag {
        switch self {
        case .defaultAds: return .default
        case .forceAds: return .forceAds
        case .ignoreMega: return .ignoreMega
        case .ignoreCountry: return .ignoreCountry
        case .ignoreIP: return .ignoreIP
        case .ignorePro: return .ignorePRO
        case .ignoreRollout: return .ignoreRollout
        }
    }
}
