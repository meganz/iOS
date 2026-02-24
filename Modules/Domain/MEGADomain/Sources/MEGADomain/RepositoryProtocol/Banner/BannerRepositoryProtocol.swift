public protocol BannerRepositoryProtocol: RepositoryProtocol {
    func banners(
        variant: Int,
        completion: @escaping @Sendable (Result<[BannerEntity], BannerErrorEntity>) -> Void
    )

    func dismissBanner(
        withBannerId bannerId: Int,
        completion: (@Sendable (Result<Void, BannerErrorEntity>) -> Void)?
    )
}
