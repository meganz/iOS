public protocol UserBannerUseCaseProtocol {
    
    /// Get the banners based on their variant
    /// - Discussion:
    /// - Parameters:
    ///   - variant: The variant we want to fetch
    ///           - variant = 0 means the legacy banners with longer description and no button text
    ///           - variant = 1 is for the new, revamped banner with more concise description and have a button text
    ///   - completion: completion handler for the result
    func banners(variant: Int, completion: @escaping @Sendable (Result<[BannerEntity], BannerErrorEntity>) -> Void)

    func dismissBanner(withBannerId bannerId: Int,
                       completion: (@Sendable (Result<Void, BannerErrorEntity>) -> Void)?)

    func bannerCategory(withBannerId bannerId: Int) -> UserBannerUseCase.BannerCategory
}

public struct UserBannerUseCase: UserBannerUseCaseProtocol {

    let userBannerRepository: any BannerRepositoryProtocol
    
    public init(userBannerRepository: any BannerRepositoryProtocol) {
        self.userBannerRepository = userBannerRepository
    }

    // MARK: - UserBannerUseCaseProtocol

    public func banners(variant: Int, completion: @escaping @Sendable (Result<[BannerEntity], BannerErrorEntity>) -> Void) {
        userBannerRepository.banners(variant: variant, completion: completion)
    }

    public func dismissBanner(withBannerId bannerId: Int,
                              completion: (@Sendable (Result<Void, BannerErrorEntity>) -> Void)?) {
        userBannerRepository.dismissBanner(withBannerId: bannerId, completion: completion)
    }

    public func bannerCategory(withBannerId bannerId: Int) -> BannerCategory {
        switch bannerId {
        case 1: return .achievement
        case 2: return .referal
        default: return .undefined
        }
    }

    // MARK: -
    public enum BannerCategory {
        case referal
        case achievement
        case undefined
    }
}
