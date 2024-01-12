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
    
    enum SharedView {
        case explorerAudioFirstGradient
        case explorerAudioSecondGradient
        case explorerDocumentsFirstGradient
        case explorerDocumentsSecondGradient
        case explorerForegroundDark
        case explorerGradientDarkBlue
        case explorerGradientLightBlue
        case gradientPink
        case gradientRed
        case pasteImageBorder
        case verifyEmailFirstGradient
        case verifyEmailSecondGradient
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .videoRevamp) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .videoRevamp) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case .explorerAudioFirstGradient:
                TokenColors.Button.brand
            case .explorerAudioSecondGradient:
                TokenColors.Button.brand
            case .explorerDocumentsFirstGradient:
                TokenColors.Button.brand
            case .explorerDocumentsSecondGradient:
                TokenColors.Button.brand
            case .explorerForegroundDark:
                TokenColors.Text.primary
            case .explorerGradientDarkBlue:
                TokenColors.Button.brand
            case .explorerGradientLightBlue:
                TokenColors.Button.brand
            case .gradientPink:
                TokenColors.Button.brand
            case .gradientRed:
                TokenColors.Button.brand
            case .pasteImageBorder:
                TokenColors.Button.brand
            case .verifyEmailFirstGradient:
                TokenColors.Button.brand
            case .verifyEmailSecondGradient:
                TokenColors.Button.brand
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case .explorerAudioFirstGradient:
                UIColor.explorerAudioFirstGradient
            case .explorerAudioSecondGradient:
                UIColor.explorerAudioSecondGradient
            case .explorerDocumentsFirstGradient:
                UIColor.explorerDocumentsFirstGradient
            case .explorerDocumentsSecondGradient:
                UIColor.explorerDocumentsSecondGradient
            case .explorerForegroundDark:
                UIColor.explorerForegroundDark
            case .explorerGradientDarkBlue:
                UIColor.explorerGradientDarkBlue
            case .explorerGradientLightBlue:
                UIColor.explorerGradientLightBlue
            case .gradientPink:
                UIColor.gradientPink
            case .gradientRed:
                UIColor.gradientRed
            case .pasteImageBorder:
                UIColor.pasteImageBorder
            case .verifyEmailFirstGradient:
                UIColor.verifyEmailFirstGradient
            case .verifyEmailSecondGradient:
                UIColor.verifyEmailSecondGradient
            }
        }
    }
}
