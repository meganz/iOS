import SwiftUI

extension ThumbnailUseCaseProtocol {
    func cachedThumbnailImage(for node: NodeEntity, type: ThumbnailTypeEntity) -> Image? {
        Image(contentsOfFile: cachedThumbnail(for: node, type: type).path)
    }
}
