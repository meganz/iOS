@objc final class NodeEntity: NSObject {
    
    init(
        // MARK: - Types
        
        changeTypes: ChangeTypeEntity,
        nodeType: NodeTypeEntity?,
        
        // MARK: - Identification
        
        name: String,
        tag: Int,
        fingerprint: String?,
        
        // MARK: - Handles
        
        handle: MEGAHandle,
        base64Handle: String,
        ownerHandle: MEGAHandle,
        restoreParentHandle: MEGAHandle,
        parentHandle: MEGAHandle,
        
        // MARK: - Attributes
        
        isFile: Bool,
        isFolder: Bool,
        isRemoved: Bool,
        hasThumnail: Bool,
        hasPreview: Bool,
        isPublic: Bool,
        isShare: Bool,
        isOutShare: Bool,
        isInShare: Bool,
        isExported: Bool,
        isExpired: Bool,
        isTakenDown: Bool,
        
        // MARK: - Links
        
        publicHandle: MEGAHandle,
        expirationTime: Date?,
        publicLinkCreationTime: Date?,
        
        // MARK: - Files
        
        size: UInt64,
        createTime: Date?,
        modificationTime: Date,
        
        // MARK: - Media
        
        width: Int,
        height: Int,
        shortFormat: Int,
        codecId: Int,
        duration: Int,
        
        // MARK: - Photo
        
        latitude: Double?,
        longitude: Double?
    ) {
        // MARK: - Types
        self.changeTypes                        = changeTypes
        self.nodeType                           = nodeType

        // MARK: - Identification

        self.name                               = name
        self.tag                                = tag
        self.fingerprint                        = fingerprint

        // MARK: - Handles

        self.handle                             = handle
        self.base64Handle                       = base64Handle
        self.ownerHandle                        = ownerHandle
        self.restoreParentHandle                = restoreParentHandle
        self.parentHandle                       = parentHandle

        // MARK: - Attributes

        self.isFile                             = isFile
        self.isFolder                           = isFolder
        self.isRemoved                          = isRemoved
        self.hasThumnail                        = hasThumnail
        self.hasPreview                         = hasPreview
        self.isPublic                           = isPublic
        self.isShare                            = isShare
        self.isOutShare                         = isOutShare
        self.isInShare                          = isInShare
        self.isExported                         = isExported
        self.isExpired                          = isExpired
        self.isTakenDown                        = isTakenDown

        // MARK: - Links

        self.publicHandle                       = publicHandle
        self.expirationTime                     = expirationTime
        self.publicLinkCreationTime             = publicLinkCreationTime

        // MARK: - Files

        self.size                               = size
        self.createTime                         = createTime
        self.modificationTime                   = modificationTime

        // MARK: - Media

        self.width                              = width
        self.height                             = height
        self.shortFormat                        = shortFormat
        self.codecId                            = codecId
        self.duration                           = duration

        // MARK: - Photo

        self.latitude                           = latitude
        self.longitude                          = longitude
    }

    // MARK: - Types

    let changeTypes: ChangeTypeEntity
    let nodeType: NodeTypeEntity?

    // MARK: - Identification

    let name: String
    let fingerprint: String?
    let tag: Int

    // MARK: - Handles

    let handle: MEGAHandle
    let base64Handle: String
    let restoreParentHandle: MEGAHandle
    let ownerHandle: MEGAHandle
    let parentHandle: MEGAHandle

    // MARK: - Attributes

    let isFile: Bool
    let isFolder: Bool
    let isRemoved: Bool
    let hasThumnail: Bool
    let hasPreview: Bool
    let isPublic: Bool
    let isShare: Bool
    let isOutShare: Bool
    let isInShare: Bool
    let isExported: Bool
    let isExpired: Bool
    let isTakenDown: Bool

    // MARK: - Link

    let publicHandle: MEGAHandle
    let expirationTime: Date?
    let publicLinkCreationTime: Date?

    // MARK: - File

    let size: UInt64
    let createTime: Date?
    let modificationTime: Date

    // MARK: - Media

    let width: Int
    let height: Int
    let shortFormat: Int
    let codecId: Int
    let duration: Int

    // MARK: - Photo

    let latitude: Double?
    let longitude: Double?
}
