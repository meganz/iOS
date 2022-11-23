import Foundation

public struct SetElementEntity {
    public let handle: HandleEntity
    public let order: HandleEntity
    public let nodeId: HandleEntity
    public let modificationTime: Date
    public let name: String
    
    public init(handle: HandleEntity, order: HandleEntity, nodeId: HandleEntity, modificationTime: Date, name: String) {
        self.handle = handle
        self.order = order
        self.nodeId = nodeId
        self.modificationTime = modificationTime
        self.name = name
    }
}

