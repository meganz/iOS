public enum ChatStatusEntity: CaseIterable, Sendable, Identifiable {
    case offline
    case away
    case online
    case busy
    case invalid
    
    public var id: Int {
        switch self {
        case .offline: 1
        case .away: 2
        case .online: 3
        case .busy: 4
        default: 16
        }
    }
    
    public static func options() -> [ChatStatusEntity] {
        [.online, .away, .busy, .offline]
    }
}
