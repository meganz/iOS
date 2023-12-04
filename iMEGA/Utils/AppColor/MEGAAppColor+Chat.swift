import MEGADesignToken
import MEGAPresentation
import UIKit

extension MEGAAppColor {
    enum Chat {
        case avatarBackground
        case listArchiveSwipeActionBackground
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case .avatarBackground: TokenColors.Background.blur
            case .listArchiveSwipeActionBackground: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case .avatarBackground: UIColor.chatAvatarBackground
            case .listArchiveSwipeActionBackground: UIColor.chatListArchiveSwipeActionBackground
            }
        }
    }
}
