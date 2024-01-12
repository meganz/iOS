import MEGADesignToken
import MEGAPresentation
import SwiftUI
import UIKit

extension MEGAAppColor {
    enum PSA {
        case psaImageBackground
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .videoRevamp) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .videoRevamp) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case .psaImageBackground:
                TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case .psaImageBackground:
                UIColor.psaImageBackground
            }
        }
    }
}
