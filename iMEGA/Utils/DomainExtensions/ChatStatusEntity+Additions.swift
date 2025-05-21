import MEGAAssets
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
        case .online: MEGAAssets.UIColor.chatStatusOnline
        case .offline: MEGAAssets.UIColor.chatStatusOffline
        case .away: MEGAAssets.UIColor.chatStatusAway
        case .busy: MEGAAssets.UIColor.chatStatusBusy
        default: .clear
        }
    }
}
