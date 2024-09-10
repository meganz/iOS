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
    
    func bgColor(isDarkMode: Bool) -> Color {
        switch self {
        case .new, .promo:
            TokenColors.Notifications.notificationSuccess.swiftUI
        case .none:
            Color.clear
        }
    }
    
    func textColor(isDarkMode: Bool) -> Color {
        switch self {
        case .new, .promo:
            TokenColors.Text.success.swiftUI
        case .none:
            Color.white
        }
    }
}
