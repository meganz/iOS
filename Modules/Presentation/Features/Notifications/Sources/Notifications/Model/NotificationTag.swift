import MEGADesignToken
import MEGAL10n
import SwiftUI

public enum NotificationTag {
    case none, new, promo
    
    var displayName: String {
        switch self {
        case .none:
            ""
        case .new:
            Strings.Localizable.new
        case .promo:
            Strings.Localizable.Notifications.Tag.Promo.title
        }
    }
    
    func bgColor(isDesignTokenEnabled: Bool, isDarkMode: Bool) -> Color {
        switch self {
        case .new, .promo:
            isDesignTokenEnabled ? TokenColors.Notifications.notificationSuccess.swiftUI : isDarkMode ? Color(red: 0, green: 0.761, blue: 0.604) : Color(red: 0, green: 0.659, blue: 0.525)
        case .none:
            Color.clear
        }
    }
    
    func textColor(isDesignTokenEnabled: Bool, isDarkMode: Bool) -> Color {
        switch self {
        case .new, .promo:
            isDesignTokenEnabled ? TokenColors.Text.success.swiftUI : .white
        case .none:
            Color.white
        }
    }
}
