import MEGAAssets
import MEGADomain
import UIKit

/// Matches the legacy player's Now Playing artwork: the file type icon until the node's thumbnail is available.
protocol VideoNowPlayingArtworkProviding: Sendable {
    /// The file type icon for the node, shown while the thumbnail loads and kept when there is none.
    func placeholder(forNodeName name: String) -> UIImage
    /// The node's thumbnail, from the cache or downloaded; nil when it has none or it cannot be fetched.
    func thumbnail(forNodeHandle handle: HandleEntity) async -> UIImage?
}

struct VideoNowPlayingArtworkProvider: VideoNowPlayingArtworkProviding {
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol

    init(thumbnailUseCase: some ThumbnailUseCaseProtocol) {
        self.thumbnailUseCase = thumbnailUseCase
    }

    func placeholder(forNodeName name: String) -> UIImage {
        MEGAAssets.UIImage.image(forFileName: name)
    }

    func thumbnail(forNodeHandle handle: HandleEntity) async -> UIImage? {
        if let image = thumbnailUseCase.cachedThumbnail(for: handle, type: .thumbnail).flatMap(image(from:)) {
            return image
        }

        return (try? await thumbnailUseCase.loadThumbnail(for: handle, type: .thumbnail)).flatMap(image(from:))
    }

    private func image(from thumbnail: ThumbnailEntity) -> UIImage? {
        UIImage(contentsOfFile: thumbnail.url.path)
    }
}
