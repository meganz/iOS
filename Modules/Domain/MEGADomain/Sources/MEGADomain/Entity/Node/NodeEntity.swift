import Foundation

public struct NodeEntity: Sendable {
    // MARK: - Types
    public let changeTypes: ChangeTypeEntity
    public let nodeType: NodeTypeEntity?
    
    // MARK: - Identification
    public let name: String
    public let fingerprint: String?
    
    // MARK: - Handles
    public let handle: HandleEntity
    public let base64Handle: String
    public let restoreParentHandle: HandleEntity
    public let ownerHandle: HandleEntity
    public let parentHandle: HandleEntity
    
    // MARK: - Attributes
    public let isFile: Bool
    public let isFolder: Bool
    public let isRemoved: Bool
    public let hasThumbnail: Bool
    public let hasPreview: Bool
    public let isPublic: Bool
    public let isShare: Bool
    public let isOutShare: Bool
    public let isInShare: Bool
    public let isExported: Bool
    public let isExpired: Bool
    public let isTakenDown: Bool
    public let isFavourite: Bool
    public let isMarkedSensitive: Bool
    public let description: String?
    public let label: NodeLabelTypeEntity
    public let tags: [String]

    // MARK: - Link
    public let publicHandle: HandleEntity
    public let expirationTime: Date?
    public let publicLinkCreationTime: Date?
    
    // MARK: - File
    public let size: UInt64
    public let creationTime: Date
    public let modificationTime: Date
    
    // MARK: - Media
    public let width: Int
    public let height: Int
    public let shortFormat: ShortFormatEntity
    public let codecId: CodecIdEntity
    public let duration: Int
    public let mediaType: MediaTypeEntity?
    
    // MARK: - Photo
    public let latitude: Double?
    public let longitude: Double?
    
    // MARK: - Backup
    public let deviceId: String?
    
    public init(
        changeTypes: ChangeTypeEntity,
        nodeType: NodeTypeEntity?,
        name: String,
        fingerprint: String?,
        handle: HandleEntity,
        base64Handle: String,
        restoreParentHandle: HandleEntity,
        ownerHandle: HandleEntity,
        parentHandle: HandleEntity,
        isFile: Bool,
        isFolder: Bool,
        isRemoved: Bool,
        hasThumbnail: Bool,
        hasPreview: Bool,
        isPublic: Bool,
        isShare: Bool,
        isOutShare: Bool,
        isInShare: Bool,
        isExported: Bool,
        isExpired: Bool,
        isTakenDown: Bool,
        isFavourite: Bool,
        isMarkedSensitive: Bool,
        description: String?,
        label: NodeLabelTypeEntity,
        tags: [String],
        publicHandle: HandleEntity,
        expirationTime: Date?,
        publicLinkCreationTime: Date?,
        size: UInt64,
        creationTime: Date,
        modificationTime: Date,
        width: Int,
        height: Int,
        shortFormat: Int,
        codecId: Int,
        duration: Int,
        mediaType: MediaTypeEntity?,
        latitude: Double?,
        longitude: Double?,
        deviceId: String?
    ) {
        self.changeTypes = changeTypes
        self.nodeType = nodeType
        self.name = name
        self.fingerprint = fingerprint
        self.handle = handle
        self.base64Handle = base64Handle
        self.restoreParentHandle = restoreParentHandle
        self.ownerHandle = ownerHandle
        self.parentHandle = parentHandle
        self.isFile = isFile
        self.isFolder = isFolder
        self.isRemoved = isRemoved
        self.hasThumbnail = hasThumbnail
        self.hasPreview = hasPreview
        self.isPublic = isPublic
        self.isShare = isShare
        self.isOutShare = isOutShare
        self.isInShare = isInShare
        self.isExported = isExported
        self.isExpired = isExpired
        self.isTakenDown = isTakenDown
        self.isFavourite = isFavourite
        self.isMarkedSensitive = isMarkedSensitive
        self.description = description
        self.label = label
        self.tags = tags
        self.publicHandle = publicHandle
        self.expirationTime = expirationTime
        self.publicLinkCreationTime = publicLinkCreationTime
        self.size = size
        self.creationTime = creationTime
        self.modificationTime = modificationTime
        self.width = width
        self.height = height
        self.shortFormat = shortFormat
        self.codecId = codecId
        self.duration = duration
        self.mediaType = mediaType
        self.latitude = latitude
        self.longitude = longitude
        self.deviceId = deviceId
    }
}

extension NodeEntity: Hashable {
    public static func == (lhs: NodeEntity, rhs: NodeEntity) -> Bool {
        lhs.handle == rhs.handle
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(handle)
    }
}

extension NodeEntity: Identifiable {
    public var id: HandleEntity { handle }
}
