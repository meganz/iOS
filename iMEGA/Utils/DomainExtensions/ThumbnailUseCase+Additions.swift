import SwiftUI
import MEGASwiftUI
import MEGADomain

extension ThumbnailUseCaseProtocol {
    func cachedThumbnailImage(for node: NodeEntity, type: ThumbnailTypeEntity) -> Image? {
        Image(contentsOfFile: cachedThumbnail(for: node, type: type).path)
    }
    
    func cachedThumbnailImageContainer(for node: NodeEntity, type: ThumbnailTypeEntity) -> ImageContainer? {
        URLImageContainer(imageURL: cachedThumbnail(for: node, type: type))
    }
    
    func loadThumbnailImage(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> Image {
        try Task.checkCancellation()
        let url = try await loadThumbnail(for: node, type: type)
        guard let image = Image(contentsOfFile: url.path) else {
            throw(ThumbnailErrorEntity.noThumbnail(type))
        }
        return image
    }
    
    func loadThumbnailImageContainer(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> ImageContainer {
        try Task.checkCancellation()
        let url = try await loadThumbnail(for: node, type: type)
        guard let container = URLImageContainer(imageURL: url) else {
            throw(ThumbnailErrorEntity.noThumbnail(type))
        }
        return container
    }
}
