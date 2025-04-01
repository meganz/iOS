import MEGADomain
import MEGASDKRepo
import SwiftUI

public extension ThumbnailUseCaseProtocol {
    func cachedThumbnailContainer(for node: NodeEntity, type: ThumbnailTypeEntity) -> (some ImageContaining)? {
        guard let thumbnail = cachedThumbnail(for: node, type: type) else { return Optional<URLImageContainer>.none }
        return URLImageContainer(imageURL: thumbnail.url, type: type.toImageType())
    }

    func loadThumbnailContainer(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> some ImageContaining {
        try Task.checkCancellation()
        let thumbnail = try await loadThumbnail(for: node, type: type)
        guard let container = URLImageContainer(imageURL: thumbnail.url, type: type.toImageType()) else {
            throw(ThumbnailErrorEntity.noThumbnail(type))
        }
        return container
    }
}

public extension ThumbnailEntity {
    func toURLImageContainer() -> URLImageContainer? {
        URLImageContainer(imageURL: url, type: type.toImageType())
    }
}

public extension ThumbnailTypeEntity {
    func toImageType() -> ImageType {
        switch self {
        case .thumbnail:
            return .thumbnail
        case .preview:
            return .preview
        case .original:
            return .original
        }
    }
}
