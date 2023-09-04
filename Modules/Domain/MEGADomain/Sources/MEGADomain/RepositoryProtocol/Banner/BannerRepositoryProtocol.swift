public protocol BannerRepositoryProtocol: RepositoryProtocol {
    func banners(
        completion: @escaping (Result<[BannerEntity], BannerErrorEntity>) -> Void
    )

    func dismissBanner(
        withBannerId bannerId: Int,
        completion: ((Result<Void, BannerErrorEntity>) -> Void)?
    )
}
