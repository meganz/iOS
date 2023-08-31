import Foundation

public struct AlbumMetaDataEntity: Hashable, Sendable {
    public let imageCount: Int
    public let videoCount: Int
    
    public init(imageCount: Int, videoCount: Int) {
        self.imageCount = imageCount
        self.videoCount = videoCount
    }
}
