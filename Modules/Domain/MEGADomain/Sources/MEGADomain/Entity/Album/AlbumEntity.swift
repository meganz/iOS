import Foundation

public enum AlbumEntityType: Sendable {
    case favourite
    case raw
    case gif
    case user
}

public struct AlbumEntity: Sendable {
    public let setIdentifier: SetIdentifier
    public var name: String
    public var coverNode: NodeEntity?
    public var count: Int
    public let type: AlbumEntityType
    public let creationTime: Date?
    public let modificationTime: Date?
    public var sharedLinkStatus: SharedLinkStatusEntity
    public let metaData: AlbumMetaDataEntity?
    
    public init(setIdentifier: SetIdentifier,
                name: String,
                coverNode: NodeEntity?,
                count: Int,
                type: AlbumEntityType,
                creationTime: Date? = nil,
                modificationTime: Date? = nil,
                sharedLinkStatus: SharedLinkStatusEntity = .unavailable,
                metaData: AlbumMetaDataEntity? = nil) {
        self.setIdentifier = setIdentifier
        self.name = name
        self.coverNode = coverNode
        self.count = count
        self.type = type
        self.creationTime = creationTime
        self.modificationTime = modificationTime
        self.sharedLinkStatus = sharedLinkStatus
        self.metaData = metaData
    }
    
    public init(
        id: SetHandleEntity,
        name: String,
        coverNode: NodeEntity?,
        count: Int,
        type: AlbumEntityType,
        creationTime: Date? = nil,
        modificationTime: Date? = nil,
        sharedLinkStatus: SharedLinkStatusEntity = .unavailable,
        metaData: AlbumMetaDataEntity? = nil
    ) {
        self.init(
            setIdentifier: SetIdentifier(handle: id),
            name: name,
            coverNode: coverNode,
            count: count,
            type: type,
            creationTime: creationTime,
            modificationTime: modificationTime,
            sharedLinkStatus: sharedLinkStatus,
            metaData: metaData
        )
    }
}

extension AlbumEntity: Identifiable {
    public var id: SetHandleEntity {
        setIdentifier.handle
    }
}

extension AlbumEntity: Hashable {
    public static func == (lhs: AlbumEntity, rhs: AlbumEntity) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.coverNode?.handle == rhs.coverNode?.handle &&
        lhs.coverNode?.isMarkedSensitive == rhs.coverNode?.isMarkedSensitive &&
        lhs.count == rhs.count &&
        lhs.type == rhs.type &&
        lhs.creationTime == rhs.creationTime &&
        lhs.modificationTime == rhs.modificationTime &&
        lhs.sharedLinkStatus == rhs.sharedLinkStatus &&
        lhs.metaData == rhs.metaData
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
