import Foundation

public struct SetEntity: Hashable, Sendable {
    public let handle: HandleEntity
    public let userId: HandleEntity
    public let coverId: HandleEntity
    public let creationTime: Date
    public let modificationTime: Date
    public let name: String
    public let isExported: Bool
    public let changes: SetChangesEntity
    
    public init(handle: HandleEntity, userId: HandleEntity, coverId: HandleEntity, creationTime: Date, 
                modificationTime: Date, name: String, isExported: Bool, changes: SetChangesEntity) {
        self.handle = handle
        self.userId = userId
        self.coverId = coverId
        self.creationTime = creationTime
        self.modificationTime = modificationTime
        self.name = name
        self.isExported = isExported
        self.changes = changes
    }
}

extension SetEntity: Identifiable {
    public var id: HandleEntity { handle }
}
