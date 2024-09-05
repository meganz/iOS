import Foundation

public struct UserAlertEntity: Sendable {
    public var identifier: UInt
    public var isSeen: Bool
    public var isRelevant: Bool
    public var alertType: UserAlertTypeEntity?
    public var alertTypeString: String?
    public var userHandle: HandleEntity?
    public var nodeHandle: HandleEntity?
    public var email: String?
    public var path: String?
    public var name: String?
    public var heading: String?
    public var title: String?
    public var isOwnChange: Bool
    
    public init(identifier: UInt, isSeen: Bool, isRelevant: Bool, alertType: UserAlertTypeEntity?, alertTypeString: String?, userHandle: HandleEntity?, nodeHandle: HandleEntity?, email: String?, path: String?, name: String?, heading: String?, title: String?, isOwnChange: Bool) {
        self.identifier = identifier
        self.isSeen = isSeen
        self.isRelevant = isRelevant
        self.alertType = alertType
        self.alertTypeString = alertTypeString
        self.userHandle = userHandle
        self.nodeHandle = nodeHandle
        self.email = email
        self.path = path
        self.name = name
        self.heading = heading
        self.title = title
        self.isOwnChange = isOwnChange
    }
}

extension UserAlertEntity: Equatable {
    public static func == (lhs: UserAlertEntity, rhs: UserAlertEntity) -> Bool {
        lhs.identifier == rhs.identifier
    }
}
