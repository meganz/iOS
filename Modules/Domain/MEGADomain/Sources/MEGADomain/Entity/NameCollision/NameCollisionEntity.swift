import Foundation

public struct NameCollisionEntity: Equatable, Sendable {
    public let parentHandle: HandleEntity
    public let name: String
    public let isFile: Bool
    public let fileUrl: URL?
    public let nodeHandle: HandleEntity?
    public var renamed: String?
    public var collisionAction: NameCollisionActionType?
    public var collisionNodeHandle: HandleEntity?
    
    public init(parentHandle: HandleEntity, name: String, isFile: Bool, fileUrl: URL? = nil, nodeHandle: HandleEntity? = nil) {
        self.parentHandle = parentHandle
        self.name = name
        self.isFile = isFile
        self.fileUrl = fileUrl
        self.nodeHandle = nodeHandle
        self.collisionAction = nil
        self.collisionNodeHandle = nil
    }
}
