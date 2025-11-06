@testable import ContentLibraries
import MEGAAppPresentation
import MEGADomain
import SwiftUI

final class MockVideoPlaylistThumbnailLoader: VideoPlaylistThumbnailLoaderProtocol, @unchecked Sendable {
    
    private(set) var loadThumbnailsCallCount = 0
    
    func loadThumbnails(for videos: [NodeEntity]) async -> VideoPlaylistThumbnail {
        loadThumbnailsCallCount += 1
        let imageContainers = videos
            .map { _ in ImageContainer(image: Image(systemName: "square.fill"), type: .placeholder) }
        return VideoPlaylistThumbnail(type: .normal, imageContainers: imageContainers)
    }
}
