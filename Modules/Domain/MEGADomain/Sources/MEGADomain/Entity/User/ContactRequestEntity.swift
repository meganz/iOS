import Foundation

public struct ContactRequestEntity: Sendable {
    public let handle: HandleEntity
    public let sourceEmail: String?
    public let sourceMessage: String?
    public let targetEmail: String?
    public let creationTime: Date?
    public let modificationTime: Date?
    public let isOutgoing: Bool
    public let status: ContactRequestStatusEntity?
    
    public init(handle: HandleEntity, sourceEmail: String?, sourceMessage: String?, targetEmail: String?, creationTime: Date?, modificationTime: Date?, isOutgoing: Bool, status: ContactRequestStatusEntity?) {
        self.handle = handle
        self.sourceEmail = sourceEmail
        self.sourceMessage = sourceMessage
        self.targetEmail = targetEmail
        self.creationTime = creationTime
        self.modificationTime = modificationTime
        self.isOutgoing = isOutgoing
        self.status = status
    }
}

extension ContactRequestEntity: Equatable {
    public static func == (lhs: ContactRequestEntity, rhs: ContactRequestEntity) -> Bool {
        lhs.handle == rhs.handle
    }
}
