import Foundation

public struct VideoPlaylistEntity: Identifiable, Hashable, Sendable {
    public let id: HandleEntity
    public var name: String
    public var coverNode: NodeEntity?
    public var count: Int
    public let type: VideoPlaylistEntityType
    public let creationTime: Date?
    public let modificationTime: Date?
    public var sharedLinkStatus: SharedLinkStatusEntity
    
    public init(
        id: HandleEntity,
        name: String,
        coverNode: NodeEntity?,
        count: Int,
        type: VideoPlaylistEntityType,
        creationTime: Date? = nil,
        modificationTime: Date? = nil,
        sharedLinkStatus: SharedLinkStatusEntity = .unavailable
    ) {
        self.id = id
        self.name = name
        self.coverNode = coverNode
        self.count = count
        self.type = type
        self.creationTime = creationTime
        self.modificationTime = modificationTime
        self.sharedLinkStatus = sharedLinkStatus
    }
}

extension VideoPlaylistEntity {
    public var isSystemVideoPlaylist: Bool {
        type == .favourite
    }
    
    public var isLinkShared: Bool {
        sharedLinkStatus == .exported(true)
    }
}

public enum VideoPlaylistEntityType: Sendable {
    case favourite
    case user
}
