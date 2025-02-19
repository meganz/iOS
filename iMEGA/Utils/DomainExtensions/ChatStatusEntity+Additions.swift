import MEGADomain
import MEGAL10n

extension ChatStatusEntity {
    var identifier: String? {
        switch self {
        case .offline: "offline"
        case .away: "away"
        case .online: "online"
        case .busy: "busy"
        default: nil
        }
    }
    
    var uiColor: UIColor {
        switch self {
        case .online: UIColor.chatStatusOnline
        case .offline: UIColor.chatStatusOffline
        case .away: UIColor.chatStatusAway
        case .busy: UIColor.chatStatusBusy
        default: .clear
        }
    }
}
