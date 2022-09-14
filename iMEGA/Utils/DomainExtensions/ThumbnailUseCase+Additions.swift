import SwiftUI
import MEGASwiftUI
import MEGADomain

extension ThumbnailUseCaseProtocol {
    func cachedThumbnailImageContainer(for node: NodeEntity, type: ThumbnailTypeEntity) -> (some ImageContaining)? {
        URLImageContainer(imageURL: cachedThumbnail(for: node, type: type))
    }

    func loadThumbnailImageContainer(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> some ImageContaining {
        try Task.checkCancellation()
        let url = try await loadThumbnail(for: node, type: type)
        guard let container = URLImageContainer(imageURL: url) else {
            throw(ThumbnailErrorEntity.noThumbnail(type))
        }
        return container
    }
}
