struct NodeEntity {
    // MARK: - Types
    
    let changeTypes: ChangeTypeEntity
    let nodeType: NodeTypeEntity?
    
    // MARK: - Identification
    
    let name: String
    let fingerprint: String?
    
    // MARK: - Handles
    
    let handle: HandleEntity
    let base64Handle: String
    let restoreParentHandle: HandleEntity
    let ownerHandle: HandleEntity
    let parentHandle: HandleEntity
    
    // MARK: - Attributes
    
    let isFile: Bool
    let isFolder: Bool
    let isRemoved: Bool
    let hasThumbnail: Bool
    let hasPreview: Bool
    let isPublic: Bool
    let isShare: Bool
    let isOutShare: Bool
    let isInShare: Bool
    let isExported: Bool
    let isExpired: Bool
    let isTakenDown: Bool
    let isFavourite: Bool
    let label: NodeLabelTypeEntity
    
    // MARK: - Link
    
    let publicHandle: HandleEntity
    let expirationTime: Date?
    let publicLinkCreationTime: Date?
    
    // MARK: - File
    
    let size: UInt64
    let creationTime: Date
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

extension NodeEntity: Hashable {
    static func == (lhs: NodeEntity, rhs: NodeEntity) -> Bool {
        lhs.handle == rhs.handle
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(handle)
    }
}

extension NodeEntity: Identifiable {
    var id: HandleEntity { handle }
}
