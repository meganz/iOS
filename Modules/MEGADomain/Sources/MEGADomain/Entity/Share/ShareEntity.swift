import Foundation

public struct ShareEntity: Sendable {
    public let sharedUserEmail: String?
    public let nodeHandle: HandleEntity
    public let accessLevel: ShareAccessLevelEntity
    public let createdDate: Date
    public let isPending: Bool
    public let isVerified: Bool
    
    public init(sharedUserEmail: String?, nodeHandle: HandleEntity, accessLevel: ShareAccessLevelEntity, createdDate: Date, isPending: Bool, isVerified: Bool) {
        self.sharedUserEmail = sharedUserEmail
        self.nodeHandle = nodeHandle
        self.accessLevel = accessLevel
        self.createdDate = createdDate
        self.isPending = isPending
        self.isVerified = isVerified
    }
}

extension ShareEntity: Hashable {
    public static func == (lhs: ShareEntity, rhs: ShareEntity) -> Bool {
        lhs.nodeHandle == rhs.nodeHandle
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(nodeHandle)
    }
}

extension ShareEntity: Identifiable {
    public var id: HandleEntity { nodeHandle }
}
