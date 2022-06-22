
enum ChatStatus: Int, CaseIterable {
    case offline = 1
    case away
    case online
    case busy
    case invalid = 15
    
    var localizedIdentifier: String? {
        switch self {
        case .offline: return Strings.Localizable.offline
        case .away: return Strings.Localizable.away
        case .online: return Strings.Localizable.online
        case .busy: return Strings.Localizable.busy
        default: return nil
        }
    }
    
    var identifier: String? {
        switch self {
        case .offline: return "offline"
        case .away: return "away"
        case .online: return "online"
        case .busy: return "busy"
        default: return nil
        }
    }
}
