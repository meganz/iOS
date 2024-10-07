@testable import MEGA
import MEGADomain

final class MockUserBannerUseCase: UserBannerUseCaseProtocol {
    private var bannersResult: Result<[BannerEntity], BannerErrorEntity>?
    private(set) var lastDismissedBannerId: Int?
    
    init(bannersResult: Result<[BannerEntity], BannerErrorEntity>? = nil) {
        self.bannersResult = bannersResult
    }
    
    func banners(completion: @escaping (Result<[BannerEntity], BannerErrorEntity>) -> Void) {
        if let bannersResult = bannersResult {
            completion(bannersResult)
        }
    }
    
    func dismissBanner(withBannerId bannerId: Int, completion: ((Result<Void, BannerErrorEntity>) -> Void)?) {
        lastDismissedBannerId = bannerId
        completion?(.success)
    }
    
    func bannerCategory(withBannerId bannerId: Int) -> UserBannerUseCase.BannerCategory {
        .achievement
    }
}
