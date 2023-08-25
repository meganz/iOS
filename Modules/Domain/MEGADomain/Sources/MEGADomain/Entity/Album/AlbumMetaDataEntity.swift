import Foundation

public struct AlbumMetaDataEntity: Hashable, Sendable {
    let imageCount: UInt
    let videoCount: UInt
    
    public init(imageCount: UInt, videoCount: UInt) {
        self.imageCount = imageCount
        self.videoCount = videoCount
    }
}
