import MEGAAppPresentation

public struct VideoPlaylistThumbnail: Sendable {
    public let type: VideoPlaylistThumbnailCoverImageType
    public let imageContainers: [(any ImageContaining)]
    
    public init(type: VideoPlaylistThumbnailCoverImageType, imageContainers: [any ImageContaining]) {
        self.type = type
        self.imageContainers = imageContainers
    }
}
