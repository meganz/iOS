import MEGADomain
import MEGAPresentation
import SwiftUI
@testable import Video

final class MockVideoPlaylistThumbnailLoader: VideoPlaylistThumbnailLoaderProtocol {
    
    private(set) var loadThumbnailsCallCount = 0
    
    func loadThumbnails(for videos: [NodeEntity]) async -> [(any ImageContaining)] {
        loadThumbnailsCallCount += 1
        return videos
            .map { _ in ImageContainer(image: Image(systemName: "square.fill"), type: .placeholder) }
    }
}
