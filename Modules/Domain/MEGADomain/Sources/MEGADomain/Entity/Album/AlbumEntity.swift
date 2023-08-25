import Foundation

public enum AlbumEntityType: Sendable {
    case favourite
    case raw
    case gif
    case user
}

public struct AlbumEntity: Identifiable, Hashable, Sendable {
    public let id: HandleEntity
    public var name: String
    public var coverNode: NodeEntity?
    public var count: Int
    public let type: AlbumEntityType
    public let creationTime: Date?
    public let modificationTime: Date?
    public var sharedLinkStatus: SharedLinkStatusEntity
    public let metaData: AlbumMetaDataEntity?
    
    public init(id: HandleEntity,
                name: String,
                coverNode: NodeEntity?,
                count: Int,
                type: AlbumEntityType,
                creationTime: Date? = nil,
                modificationTime: Date? = nil,
                sharedLinkStatus: SharedLinkStatusEntity = .unavailable,
                metaData: AlbumMetaDataEntity? = nil) {
        self.id = id
        self.name = name
        self.coverNode = coverNode
        self.count = count
        self.type = type
        self.creationTime = creationTime
        self.modificationTime = modificationTime
        self.sharedLinkStatus = sharedLinkStatus
        self.metaData = metaData
    }
}

extension AlbumEntity {
    public var systemAlbum: Bool {
        type == .raw || type == .gif || type == .favourite
    }
    
    public var isLinkShared: Bool {
        sharedLinkStatus == .exported(true)
    }
}
