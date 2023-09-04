public protocol UserBannerUseCaseProtocol {

    func banners(completion: @escaping (Result<[BannerEntity], BannerErrorEntity>) -> Void)

    func dismissBanner(withBannerId bannerId: Int,
                       completion: ((Result<Void, BannerErrorEntity>) -> Void)?)

    func bannerCategory(withBannerId bannerId: Int) -> UserBannerUseCase.BannerCategory
}

public struct UserBannerUseCase: UserBannerUseCaseProtocol {

    let userBannerRepository: any BannerRepositoryProtocol
    
    public init(userBannerRepository: any BannerRepositoryProtocol) {
        self.userBannerRepository = userBannerRepository
    }

    // MARK: - UserBannerUseCaseProtocol

    public func banners(completion: @escaping (Result<[BannerEntity], BannerErrorEntity>) -> Void) {
        userBannerRepository.banners(completion: completion)
    }

    public func dismissBanner(withBannerId bannerId: Int,
                              completion: ((Result<Void, BannerErrorEntity>) -> Void)?) {
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
