import SwiftUI

extension ThumbnailUseCaseProtocol {
    func cachedThumbnailImage(for node: NodeEntity, type: ThumbnailTypeEntity) -> Image? {
        Image(contentsOfFile: cachedThumbnail(for: node, type: type).path)
    }
    
    func loadThumbnailImage(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> Image {
        try Task.checkCancellation()
        let url = try await loadThumbnail(for: node, type: type)
        guard let image = Image(contentsOfFile: url.path) else {
            throw(ThumbnailErrorEntity.noThumbnail(type))
        }
        return image
    }
}
