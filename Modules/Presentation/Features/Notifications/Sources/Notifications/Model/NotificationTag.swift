import MEGAL10n

public enum NotificationTag {
    case none, new, promo
    
    public var displayName: String {
        switch self {
        case .none:
            return ""
        case .new:
            return Strings.Localizable.new
        case .promo:
            return Strings.Localizable.Notifications.Tag.Promo.title
        }
    }
}
