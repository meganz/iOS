protocol BannerRepositoryProtocol {

    func banners(
        completion: @escaping (Result<[BannerEntity], BannerErrorEntity>) -> Void
    )

    func dismissBanner(
        withBannerId bannerId: Int,
        completion: ((Result<Void, BannerErrorEntity>) -> Void)?
    )
}

struct BannerRepository: BannerRepositoryProtocol {

    let sdk: MEGASdk

    // MARK: - BannerRepositoryProtocol

    func banners(completion: @escaping (Result<[BannerEntity], BannerErrorEntity>) -> Void) {

        func mapError(sdkError: MEGASDKErrorType) -> BannerErrorEntity {
            switch sdkError {
            case .accessDenied: return .userSessionTimeout
            case .internalError: return .internal
            case .resourceNotExists: return .resourceDoesNotExist
            default: return .unexpected
            }
        }

        func mapValue(request: MEGARequest) -> [BannerEntity] {
            request.bannerList.bannerEntities
        }

        let sdkDelegate = MEGAResultRequestDelegate { (result) in
            switch result {
            case .failure(let errorType):
                completion(.failure(mapError(sdkError: errorType)))
            case .success(let request):
                completion(.success(request.bannerList.bannerEntities))
            }
        }
        sdk.getBanners(sdkDelegate)
    }

    func dismissBanner(
        withBannerId bannerId: Int,
        completion: ((Result<Void, BannerErrorEntity>) -> Void)?
    ) {
        let sdkDelegate = MEGAResultMappingRequestDelegate(
            completion: completion ?? { _ in },
            mapValue: { _ in return () },
            mapError: { _ in return .unexpected }
        )
        sdk.dismissBanner(bannerId, delegate: sdkDelegate)
    }
}
