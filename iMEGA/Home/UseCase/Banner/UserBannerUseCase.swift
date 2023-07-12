protocol UserBannerUseCaseProtocol {

    func banners(completion: @escaping (Result<[BannerEntity], BannerErrorEntity>) -> Void)

    func dismissBanner(withBannerId bannerId: Int,
                       completion: ((Result<Void, BannerErrorEntity>) -> Void)?)

    func bannerCategory(withBannerId bannerId: Int) -> UserBannerUseCase.BannerCategory
}

struct UserBannerUseCase: UserBannerUseCaseProtocol {

    let userBannerRepository: any BannerRepositoryProtocol

    // MARK: - UserBannerUseCaseProtocol

    func banners(completion: @escaping (Result<[BannerEntity], BannerErrorEntity>) -> Void) {
        userBannerRepository.banners(completion: completion)
    }

    func dismissBanner(withBannerId bannerId: Int,
                       completion: ((Result<Void, BannerErrorEntity>) -> Void)?) {
        userBannerRepository.dismissBanner(withBannerId: bannerId, completion: completion)
    }

    func bannerCategory(withBannerId bannerId: Int) -> BannerCategory {
        switch bannerId {
        case 1: return .achievement
        case 2: return .referal
        default: return .undefined
        }
    }

    // MARK: -
    enum BannerCategory {
        case referal
        case achievement
        case undefined
    }
}
