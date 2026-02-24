import MEGADomain
import MEGASdk

extension MEGABannerList {
    public func bannerEntities(variant: Int = 0) -> [BannerEntity] {
        (0..<size).compactMap { index -> BannerEntity? in
            guard let banner = banner(at: index) else { return nil }
            guard banner.variant == variant else { return nil }
            return banner.bannerEntity
        }
    }
}
