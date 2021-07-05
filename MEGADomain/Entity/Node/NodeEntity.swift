struct NodeEntity {
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
