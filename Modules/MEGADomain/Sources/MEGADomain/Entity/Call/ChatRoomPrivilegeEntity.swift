
public enum ChatRoomPrivilegeEntity {
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
}
