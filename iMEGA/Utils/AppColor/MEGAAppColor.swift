import MEGADesignToken
import MEGAPresentation
import UIKit

enum MEGAAppColor {
    enum White {
        case _FFFFFF
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._FFFFFF: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._FFFFFF: UIColor.whiteFFFFFF
            }
        }
    }
    
    enum Black {
        case _00000015
        case _00000032
        case _2C2C2E
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._00000015: TokenColors.Background.blur
            case ._00000032: TokenColors.Background.blur
            case ._2C2C2E: TokenColors.Background.blur
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._00000015: UIColor.black00000015
            case ._00000032: UIColor.black00000032
            case ._2C2C2E: UIColor.black2C2C2E
            }
        }
    }
    
    enum Gray {
        case _1D1D1D
        case _3A3A3C
        case _3C3C43
        case _3D3D3D
        case _3F3F42
        case _8E8E93
        case _9B9B9B
        case _545A68
        case _04040F
        case _333333
        case _363638
        case _474747
        
        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }
        
        private var designTokenColor: UIColor {
            switch self {
            case ._1D1D1D: TokenColors.Text.primary
            case ._3A3A3C: TokenColors.Background.blur
            case ._3C3C43: TokenColors.Text.secondary
            case ._3D3D3D: TokenColors.Background.blur
            case ._3F3F42: TokenColors.Text.primary
            case ._8E8E93: TokenColors.Text.secondary
            case ._9B9B9B: TokenColors.Text.secondary
            case ._545A68: TokenColors.Text.primary
            case ._04040F: TokenColors.Text.primary
            case ._333333: TokenColors.Text.primary
            case ._363638: TokenColors.Text.primary
            case ._474747: TokenColors.Text.primary
            }
        }
        
        private var legacyColor: UIColor {
            switch self {
            case ._1D1D1D: UIColor.gray1D1D1D
            case ._3A3A3C: UIColor.gray3A3A3C
            case ._3C3C43: UIColor.gray3C3C43
            case ._3D3D3D: UIColor.gray3D3D3D
            case ._3F3F42: UIColor.gray3F3F42
            case ._8E8E93: UIColor.gray8E8E93
            case ._9B9B9B: UIColor.gray9B9B9B
            case ._545A68: UIColor.gray545A68
            case ._04040F: UIColor.gray04040F
            case ._333333: UIColor.gray333333
            case ._363638: UIColor.gray363638
            case ._474747: UIColor.gray474747
            }
        }
    }
}
