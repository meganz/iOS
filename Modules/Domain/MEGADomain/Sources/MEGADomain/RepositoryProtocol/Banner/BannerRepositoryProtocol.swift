public protocol BannerRepositoryProtocol: RepositoryProtocol {
    func banners(
        completion: @escaping @Sendable (Result<[BannerEntity], BannerErrorEntity>) -> Void
    )

    func dismissBanner(
        withBannerId bannerId: Int,
        completion: (@Sendable (Result<Void, BannerErrorEntity>) -> Void)?
    )
}
