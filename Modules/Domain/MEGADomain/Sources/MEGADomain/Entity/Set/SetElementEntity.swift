import Foundation

public struct SetElementEntity: Hashable, Sendable {
    public let handle: HandleEntity
    public let ownerId: HandleEntity
    public let order: HandleEntity
    public let nodeId: HandleEntity
    public let modificationTime: Date
    public let name: String
    public let changeTypes: SetElementChangeTypeEntity
    
    public init(handle: HandleEntity, ownerId: HandleEntity, order: HandleEntity,
                nodeId: HandleEntity, modificationTime: Date, name: String,
                changeTypes: SetElementChangeTypeEntity) {
        self.handle = handle
        self.ownerId = ownerId
        self.order = order
        self.nodeId = nodeId
        self.modificationTime = modificationTime
        self.name = name
        self.changeTypes = changeTypes
    }
}

extension SetElementEntity: Identifiable {
    public var id: HandleEntity { handle }
}
