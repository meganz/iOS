import MEGADomain
import MEGASdk

public struct BannerRepository: BannerRepositoryProtocol {
    public static var newRepo: BannerRepository {
        BannerRepository(sdk: MEGASdk.sharedSdk)
    }
    
    let sdk: MEGASdk

    // MARK: - BannerRepositoryProtocol

    public func banners(completion: @escaping @Sendable (Result<[BannerEntity], BannerErrorEntity>) -> Void) {

        @Sendable func mapError(sdkError: MEGAErrorType) -> BannerErrorEntity {
            switch sdkError {
            case .apiEAccess: return .userSessionTimeout
            case .apiEInternal: return .internal
            case .apiENoent: return .resourceDoesNotExist
            default: return .unexpected
            }
        }

        func mapValue(request: MEGARequest) -> [BannerEntity] {
            request.bannerList?.bannerEntities ?? []
        }

        sdk.getBanners(RequestDelegate { result in
            switch result {
            case .failure(let error):
                completion(.failure(mapError(sdkError: error.type)))
            case .success(let request):
                completion(.success(request.bannerList?.bannerEntities ?? []))
            }
        })
    }

    public func dismissBanner(
        withBannerId bannerId: Int,
        completion: (@Sendable (Result<Void, BannerErrorEntity>) -> Void)?
    ) {
        sdk.dismissBanner(bannerId, delegate: RequestDelegate { result in
            switch result {
            case .failure:
                completion?(.failure(.unexpected))
            case .success:
                completion?(.success(()))
            }
        })
    }
}
