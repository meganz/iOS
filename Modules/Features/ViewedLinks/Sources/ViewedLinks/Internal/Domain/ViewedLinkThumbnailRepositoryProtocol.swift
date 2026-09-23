import MEGADomain

package protocol ViewedLinkThumbnailRepositoryProtocol: Sendable {
    func cachedThumbnail(for handle: HandleEntity) -> ThumbnailEntity?
    func loadThumbnail(for link: ViewedLinkEntity) async throws -> ThumbnailEntity
}
