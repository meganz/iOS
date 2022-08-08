import Foundation

public struct ShareEntity {
    public let sharedUserEmail: String?
    public let nodeHandle: HandleEntity
    public let accessLevel: ShareAccessLevelEntity
    public let createdDate: Date
    public let isPending: Bool
    
    public init(sharedUserEmail: String?, nodeHandle: HandleEntity, accessLevel: ShareAccessLevelEntity, createdDate: Date, isPending: Bool) {
        self.sharedUserEmail = sharedUserEmail
        self.nodeHandle = nodeHandle
        self.accessLevel = accessLevel
        self.createdDate = createdDate
        self.isPending = isPending
    }
}
