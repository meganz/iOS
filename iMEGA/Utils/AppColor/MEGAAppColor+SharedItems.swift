import MEGADesignToken
import MEGAPresentation
import SwiftUI
import UIKit

extension MEGAAppColor {
    enum SharedItems {
        case sharedItemsTabSelectedBackground
        case sharedItemsTabSelectedIconTint
        case sharedItemsTabSelectedText
        case sharedItemsTabNormalText
        case sharedItemsTabNormalIconTint
        case sharedItemsTabNormalBackground
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .videoRevamp) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .videoRevamp) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case .sharedItemsTabSelectedBackground:
                TokenColors.Button.brand
            case .sharedItemsTabSelectedIconTint:
                TokenColors.Button.brand
            case .sharedItemsTabSelectedText:
                TokenColors.Button.brand
            case .sharedItemsTabNormalText:
                TokenColors.Icon.secondary
            case .sharedItemsTabNormalIconTint:
                TokenColors.Icon.secondary
            case .sharedItemsTabNormalBackground:
                TokenColors.Border.strong
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case .sharedItemsTabSelectedBackground:
                UIColor.sharedItemsTabSelectedBackground
            case .sharedItemsTabSelectedIconTint:
                UIColor.sharedItemsTabSelectedIconTint
            case .sharedItemsTabSelectedText:
                UIColor.sharedItemsTabSelectedText
            case .sharedItemsTabNormalText:
                UIColor.sharedItemsTabNormalText
            case .sharedItemsTabNormalIconTint:
                UIColor.sharedItemsTabNormalIconTint
            case .sharedItemsTabNormalBackground:
                UIColor.sharedItemsTabNormalBackground
            }
        }
    }
}
