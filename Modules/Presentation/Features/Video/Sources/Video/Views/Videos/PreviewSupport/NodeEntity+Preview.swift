import Foundation
import MEGADomain

extension NodeEntity {
    
    static let preview = NodeEntity(
        changeTypes: .favourite,
        nodeType: .file,
        name: "Sample Item",
        fingerprint: nil,
        handle: 1,
        base64Handle: "",
        restoreParentHandle: 1,
        ownerHandle: 1,
        parentHandle: 1,
        isFile: true,
        isFolder: false,
        isRemoved: false,
        hasThumbnail: true,
        hasPreview: true,
        isPublic: false,
        isShare: true,
        isOutShare: false,
        isInShare: false,
        isExported: false,
        isExpired: false,
        isTakenDown: false,
        isFavourite: true, 
        isMarkedSensitive: false, 
        description: nil,
        label: .grey,
        tags: [],
        publicHandle: 1,
        expirationTime: nil,
        publicLinkCreationTime: nil,
        size: 0,
        creationTime: Date(),
        modificationTime: Date(),
        width: 0,
        height: 0,
        shortFormat: 0,
        codecId: 0,
        duration: 0,
        mediaType: .video,
        latitude: nil,
        longitude: nil,
        deviceId: nil
    )
}
