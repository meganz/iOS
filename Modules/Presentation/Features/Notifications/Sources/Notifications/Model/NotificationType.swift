import MEGADesignToken
import MEGAL10n
import SwiftUI

public enum NotificationType {
    case limitedTypeOffer, none
    
    var displayName: String {
        switch self {
        case .limitedTypeOffer:
            "Limited time offer" // Temporarily hardcore waiting for SDK changes
        case .none:
            ""
        }
    }
    
    func textColor(isDesignTokenEnabled: Bool, isDarkMode: Bool) -> Color {
        switch self {
        case .limitedTypeOffer:
            isDesignTokenEnabled ? TokenColors.Support.success.swiftUI : isDarkMode ? Color(red: 0, green: 0.761, blue: 0.604) : Color(red: 0, green: 0.659, blue: 0.525)
        case .none:
            Color.white
        }
    }
}
