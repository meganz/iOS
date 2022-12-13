import SwiftUI
import MEGASwiftUI
import MEGADomain

extension ThumbnailUseCaseProtocol {
    func cachedThumbnailContainer(for node: NodeEntity, type: ThumbnailTypeEntity) -> (some ImageContaining)? {
        guard let thumbnail = cachedThumbnail(for: node, type: type) else { return Optional<URLImageContainer>.none }
        return URLImageContainer(imageURL: thumbnail)
    }

    func loadThumbnailContainer(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> some ImageContaining {
        try Task.checkCancellation()
        let url = try await loadThumbnail(for: node, type: type)
        guard let container = URLImageContainer(imageURL: url) else {
            throw(ThumbnailErrorEntity.noThumbnail(type))
        }
        return container
    }
}
