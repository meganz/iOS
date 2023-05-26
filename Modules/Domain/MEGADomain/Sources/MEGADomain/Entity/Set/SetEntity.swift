import Foundation

public struct SetEntity: Hashable, Sendable {
    public let handle: HandleEntity
    public let userId: HandleEntity
    public let coverId: HandleEntity
    public let creationTime: Date
    public let modificationTime: Date
    public let name: String
    public let isExported: Bool
    public let changeTypes: SetChangeTypeEntity
    
    public init(handle: HandleEntity, userId: HandleEntity, coverId: HandleEntity, creationTime: Date,
                modificationTime: Date, name: String, isExported: Bool, changeTypes: SetChangeTypeEntity) {
        self.handle = handle
        self.userId = userId
        self.coverId = coverId
        self.creationTime = creationTime
        self.modificationTime = modificationTime
        self.name = name
        self.isExported = isExported
        self.changeTypes = changeTypes
    }
}

extension SetEntity: Identifiable {
    public var id: HandleEntity { handle }
}
