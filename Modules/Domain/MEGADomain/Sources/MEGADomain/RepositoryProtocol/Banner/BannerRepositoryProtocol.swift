public protocol BannerRepositoryProtocol: RepositoryProtocol, Sendable {
    func banners(
        variant: Int,
        completion: @escaping @Sendable (Result<[BannerEntity], BannerErrorEntity>) -> Void
    )

    func dismissBanner(
        withBannerId bannerId: Int,
        completion: (@Sendable (Result<Void, BannerErrorEntity>) -> Void)?
    )
}
