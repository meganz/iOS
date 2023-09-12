import MEGAChatSdk
import MEGADomain

extension ChatRoomPrivilegeEntity {    
    func toMEGAChatRoomPrivilege() -> MEGAChatRoomPrivilege {
        switch self {
        case .unknown:
            return .unknown
        case .removed:
            return .rm
        case .readOnly:
            return .ro
        case .standard:
            return .standard
        case .moderator:
            return .moderator
        }
    }
}
