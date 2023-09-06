public enum ChatRoomPrivilegeEntity: Sendable {
    case unknown
    case removed
    case readOnly
    case standard
    case moderator
}

extension ChatRoomPrivilegeEntity {
    public func isPeerVisibleByPrivilege() -> Bool {
        switch self {
        case .unknown, .removed:
            return false
        case .readOnly, .standard, .moderator:
            return true
        }
    }
    
    public var isUserInChat: Bool {
        switch self {
        case .unknown, .removed:
            return false
        case .readOnly, .standard, .moderator:
            return true
        }
    }
    
    public var isUserInWaitingRoom: Bool {
        switch self {
        case .unknown, .removed, .moderator:
            return false
        case .readOnly, .standard:
            return true
        }
    }
}
