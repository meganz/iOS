import MEGADesignToken
import MEGAPresentation
import SwiftUI
import UIKit

extension MEGAAppColor {
    enum Shadow {
        case blackAlpha10
        case blackAlpha20

        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }

        private var designTokenColor: UIColor {
            switch self {
            case .blackAlpha10: TokenColors.Background.blur
            case .blackAlpha20: TokenColors.Background.blur
            }
        }

        private var legacyColor: UIColor {
            switch self {
            case .blackAlpha10: UIColor.blackAlpha10
            case .blackAlpha20: UIColor.blackAlpha20
            }
        }
    }

    enum Background {
        case backgroundCell
        case navigationBgColor
        case backgroundRegularPrimaryElevated

        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }

        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }

        private var designTokenColor: UIColor {
            switch self {
            case .backgroundCell: TokenColors.Background.blur
            case .navigationBgColor:  TokenColors.Background.blur
            case .backgroundRegularPrimaryElevated:  TokenColors.Background.blur
            }
        }

        private var legacyColor: UIColor {
            switch self {
            case .backgroundCell: UIColor.backgroundCell
            case .navigationBgColor: UIColor.navigationBg
            case .backgroundRegularPrimaryElevated: UIColor.backgroundRegularPrimaryElevated
            }
        }
    }

    enum View {
        case cellBackground
        case textForeground
        case turquoise
        case turquoise_link

        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }

        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }

        private var designTokenColor: UIColor {
            switch self {
            case .cellBackground: TokenColors.Background.blur
            case .textForeground: TokenColors.Background.blur
            case .turquoise: TokenColors.Support.success
            case .turquoise_link: TokenColors.Link.primary
            }
        }

        private var legacyColor: UIColor {
            switch self {
            case .cellBackground: UIColor.cellBackground
            case .textForeground: UIColor.textForeground
            case .turquoise, .turquoise_link: UIColor.turquoise
            }
        }
    }

    enum Banner {
        case bannerWarningBackground
        case bannerWarningText

        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }

        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }

        private var designTokenColor: UIColor {
            switch self {
            case .bannerWarningBackground: TokenColors.Background.blur
            case .bannerWarningText: TokenColors.Background.blur
            }
        }

        private var legacyColor: UIColor {
            switch self {
            case .bannerWarningBackground: UIColor.bannerWarningBackground
            case .bannerWarningText: UIColor.bannerWarningText
            }
        }
    }

    enum Text {
        case primary
        case secondary

        var uiColor: UIColor {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor : legacyColor
        }

        var color: Color {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? designTokenColor.swiftUI : legacyColor.swiftUI
        }

        private var designTokenColor: UIColor {
            switch self {
            case .primary: TokenColors.Text.primary
            case .secondary: TokenColors.Text.secondary
            }
        }

        private var legacyColor: UIColor {
            switch self {
            case .primary: UIColor.label
            case .secondary: UIColor.secondaryLabel
            }
        }
    }
}
