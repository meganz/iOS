import MEGADesignToken
import MEGAPresentation
import SwiftUI
import UIKit

extension MEGAAppColor {
    enum Videos {
        case videoThumbnailImageViewPlaceholderBackgroundColor
        case videoThumbnailDurationTextBackgroundColor
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case .videoThumbnailImageViewPlaceholderBackgroundColor:
                return TokenColors.Background.blur
            case .videoThumbnailDurationTextBackgroundColor:
                return TokenColors.Background.surface1
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case .videoThumbnailImageViewPlaceholderBackgroundColor:
                return UIColor.black
            case .videoThumbnailDurationTextBackgroundColor:
                return UIColor(Color.black.opacity(0.2))
            }
        }
    }
}
