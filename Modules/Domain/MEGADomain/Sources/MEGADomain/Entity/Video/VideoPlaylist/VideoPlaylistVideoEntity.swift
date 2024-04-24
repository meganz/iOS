import Foundation

public struct VideoPlaylistVideoEntity: Hashable, Sendable {
    public let video: NodeEntity
    public let videoPlaylistVideoId: HandleEntity?
    
    public init(
        video: NodeEntity,
        videoPlaylistVideoId: HandleEntity? = nil
    ) {
        self.video = video
        self.videoPlaylistVideoId = videoPlaylistVideoId
    }
}

extension VideoPlaylistVideoEntity {
    public var id: HandleEntity { video.handle }
}
