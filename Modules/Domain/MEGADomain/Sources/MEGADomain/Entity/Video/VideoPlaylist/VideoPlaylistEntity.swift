import Foundation

public struct VideoPlaylistEntity: Identifiable, Hashable, Sendable {
    
    public var id: SetHandleEntity {
        setIdentifier.handle
    }
    
    public let setIdentifier: SetIdentifier
    public var name: String
    public var coverNode: NodeEntity?
    public var count: Int
    public let type: VideoPlaylistEntityType
    public let creationTime: Date
    public let modificationTime: Date
    public var sharedLinkStatus: SharedLinkStatusEntity
    
    public init(
        setIdentifier: SetIdentifier,
        name: String,
        coverNode: NodeEntity? = nil,
        count: Int,
        type: VideoPlaylistEntityType,
        creationTime: Date,
        modificationTime: Date,
        sharedLinkStatus: SharedLinkStatusEntity = .unavailable
    ) {
        self.setIdentifier = setIdentifier
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

public enum VideoPlaylistEntityType: Sendable, CaseIterable {
    case favourite
    case user
}
