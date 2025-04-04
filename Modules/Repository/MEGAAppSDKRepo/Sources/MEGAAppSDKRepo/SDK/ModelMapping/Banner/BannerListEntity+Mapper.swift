import MEGADomain
import MEGASdk

extension MEGABannerList {
    public var bannerEntities: [BannerEntity] {
        (0..<size).compactMap { index -> BannerEntity? in
            guard let banner = banner(at: index) else { return nil }
            return banner.bannerEntity
        }
    }
}
