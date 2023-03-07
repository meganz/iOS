import Foundation

public struct SetEntity: Hashable, Sendable {
    public let handle: HandleEntity
    public let userId: HandleEntity
    public let coverId: HandleEntity
    public let modificationTime: Date
    public let name: String
    
    public init(handle: HandleEntity, userId: HandleEntity, coverId: HandleEntity, modificationTime: Date, name: String) {
        self.handle = handle
        self.userId = userId
        self.coverId = coverId
        self.modificationTime = modificationTime
        self.name = name
    }
}

extension SetEntity: Identifiable {
    public var id: HandleEntity { handle }
}
