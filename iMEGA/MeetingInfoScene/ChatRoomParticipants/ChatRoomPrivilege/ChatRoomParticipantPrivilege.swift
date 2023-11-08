import MEGAL10n

enum ChatRoomParticipantPrivilege: String, CaseIterable {
    case unknown
    case removed
    case readOnly
    case standard
    case moderator
    
    var localizedTitle: String {
        switch self {
        case .unknown, .removed, .readOnly:
            return Strings.Localizable.readOnly
        case .standard:
            return Strings.Localizable.standard
        case .moderator:
            return Strings.Localizable.moderator
        }
    }
    
    var image: ImageResource {
        switch self {
        case .unknown, .removed, .readOnly:
            return .readOnlyChat
        case .standard:
            return .standard
        case .moderator:
            return .moderator
        }
    }
}
