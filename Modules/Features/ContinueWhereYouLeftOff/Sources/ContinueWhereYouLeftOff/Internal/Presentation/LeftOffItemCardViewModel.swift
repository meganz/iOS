import Foundation
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGASwift
import SwiftUI

@MainActor
@Observable
final class LeftOffItemCardViewModel {
    private(set) var thumbnail: (any ImageContaining)?

    private let thumbnailLoader: any ThumbnailLoaderProtocol

    var thumbnailLoaded: Bool { thumbnail != nil }

    init(thumbnailLoader: some ThumbnailLoaderProtocol) {
        self.thumbnailLoader = thumbnailLoader
    }

    func fileTypeIcon(for fileName: String) -> Image {
        MEGAAssets.Image.image(forFileExtension: fileName.pathExtension)
    }

    func loadThumbnail(for node: NodeEntity) async {
        guard node.hasThumbnail, !thumbnailLoaded, !Task.isCancelled else { return }
        let container: (any ImageContaining)? = try? await thumbnailLoader.loadImage(for: node, type: .thumbnail)
        guard let container, !Task.isCancelled else { return }
        thumbnail = container
    }
}
