import MEGADesignToken
import MEGAL10n
import SwiftUI

public enum NotificationType {
    case limitedTypeOffer, none
    
    var displayName: String {
        switch self {
        case .limitedTypeOffer:
            Strings.Localizable.Notifications.NotificationType.Promo.title
            
        case .none:
            ""
        }
    }
    
    func textColor(isDarkMode: Bool) -> Color {
        switch self {
        case .limitedTypeOffer:
            TokenColors.Support.success.swiftUI
        case .none:
            Color.white
        }
    }
}
