import MEGADomain

public protocol ViewedLinkThumbnailUseCaseProtocol: Sendable {
    func loadThumbnail(viewedLink: ViewedLinkEntity) async throws -> ThumbnailEntity
}

package struct ViewedLinkThumbnailUseCase: ViewedLinkThumbnailUseCaseProtocol {
    private let repository: any ViewedLinkThumbnailRepositoryProtocol

    package init(repository: some ViewedLinkThumbnailRepositoryProtocol) {
        self.repository = repository
    }

    package func loadThumbnail(viewedLink: ViewedLinkEntity) async throws -> ThumbnailEntity {
        guard !viewedLink.isFolder else {
            throw ThumbnailErrorEntity.noThumbnail(.thumbnail)
        }

        if let cached = repository.cachedThumbnail(for: viewedLink.handle) {
            return cached
        }

        return try await repository.loadThumbnail(for: viewedLink)
    }
}
