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
    
    var imageName: String {
        switch self {
        case .unknown, .removed, .readOnly:
            return Asset.Images.ActionSheetIcons.ChatPermissions.readOnlyChat.name
        case .standard:
            return Asset.Images.ActionSheetIcons.ChatPermissions.standard.name
        case .moderator:
            return Asset.Images.ActionSheetIcons.ChatPermissions.moderator.name
        }
    }
}
