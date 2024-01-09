import MEGADesignToken
import MEGAPresentation
import SwiftUI
import UIKit

extension MEGAAppColor {
    enum Account {
        case proAccountLite
        case proAccountRedProI
        case proAccountRedProII
        case proAccountRedProIII
        case upgradeAccountPrimaryGrayText
        case upgradeAccountPrimaryText
        case upgradeAccountSecondaryText
        case upgradeAccountSubMessageBackground
        case planBodyBackground
        case planBorderTint
        case currentPlan
        case planHeaderBackground
        case planRecommended
        case planUnselectedTint
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case .proAccountLite:
                TokenColors.Background.blur
            case .proAccountRedProI:
                TokenColors.Background.blur
            case .proAccountRedProII:
                TokenColors.Background.blur
            case .proAccountRedProIII:
                TokenColors.Background.blur
            case .upgradeAccountPrimaryGrayText:
                TokenColors.Background.blur
            case .upgradeAccountPrimaryText:
                TokenColors.Background.blur
            case .upgradeAccountSecondaryText:
                TokenColors.Background.blur
            case .upgradeAccountSubMessageBackground:
                TokenColors.Background.blur
            case .planBodyBackground:
                TokenColors.Background.blur
            case .planBorderTint:
                TokenColors.Background.blur
            case .currentPlan:
                TokenColors.Background.blur
            case .planHeaderBackground:
                TokenColors.Background.blur
            case .planRecommended:
                TokenColors.Background.blur
            case .planUnselectedTint:
                TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case .proAccountLite:
                UIColor.proAccountLITE
            case .proAccountRedProI:
                UIColor.proAccountRedProI
            case .proAccountRedProII:
                UIColor.proAccountRedProII
            case .proAccountRedProIII:
                UIColor.proAccountRedProII
            case .upgradeAccountPrimaryGrayText:
                UIColor.upgradeAccountPrimaryGrayText
            case .upgradeAccountPrimaryText:
                UIColor.upgradeAccountPrimaryText
            case .upgradeAccountSecondaryText:
                UIColor.upgradeAccountSecondaryText
            case .upgradeAccountSubMessageBackground:
                UIColor.upgradeAccountSubMessageBackground
            case .planBodyBackground:
                UIColor.bodyBackground
            case .planBorderTint:
                UIColor.borderTint
            case .currentPlan:
                UIColor.currentPlan
            case .planHeaderBackground:
                UIColor.headerBackground
            case .planRecommended:
                UIColor.recommended
            case .planUnselectedTint:
                UIColor.unselectedTint
            }
        }
    }
}
