import MEGADesignToken
import SwiftUI
import UIKit

extension MarkdownTheme {
    /// The theme as UIKit values, so UIKit text views look like the SwiftUI blocks.
    /// Fonts and sizes are resolved for `traits`. Colors stay dynamic `UIColor`s: a text view resolves them
    /// with its own traits, so a switch to dark mode needs no new `Resolved`.
    package func resolved(for traits: UITraitCollection) -> Resolved {
        Resolved(theme: self, traits: traits)
    }

    package struct Resolved {
        package let bodyFont: UIFont
        /// Body font with digits of one width, for list numbers.
        package let numberFont: UIFont
        package let inlineCodeFont: UIFont
        package let codeFont: UIFont
        package let languageFont: UIFont
        /// Levels 1...6.
        package let headingFonts: [UIFont]

        package let bodyColor: UIColor
        package let headingColor: UIColor
        package let quoteTextColor: UIColor
        package let linkColor: UIColor
        package let inlineCodeColor: UIColor
        package let inlineCodeBackground: UIColor
        package let inlineCodeBorder: UIColor
        package let codeForeground: UIColor
        package let codeBackground: UIColor
        package let codeLanguageColor: UIColor
        package let quoteBarColor: UIColor
        package let dividerColor: UIColor
        package let checkboxCheckedColor: UIColor
        package let checkboxUncheckedColor: UIColor
        package let checkboxBorderColor: UIColor
        package let checkboxTickColor: UIColor

        package let codeCornerRadius: CGFloat
        package let blockSpacing: CGFloat
        package let nestedBlockSpacing: CGFloat
        package let headingTopSpacing: CGFloat
        /// Same as the `@ScaledMetric` size of `MarkdownCheckbox`.
        package let checkboxSize: CGFloat
        /// Same as the `@ScaledMetric` offset of `ListMarkerView`, so the box stays on the first line.
        package let checkboxBaselineOffset: CGFloat
        /// False when the theme has other fonts than `MarkdownTheme.default`. UIKit cannot read a SwiftUI `Font`,
        /// so the fonts above are then the default ones. Colors and sizes still come from the theme.
        package let usesThemeFonts: Bool

        init(theme: MarkdownTheme, traits: UITraitCollection) {
            usesThemeFonts = Self.usesDefaultFonts(theme)
            let body = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traits)
            bodyFont = body
            let digits: [UIFontDescriptor.FeatureKey: Int] = [.type: kNumberSpacingType, .selector: kMonospacedNumbersSelector]
            numberFont = UIFont(descriptor: body.fontDescriptor.addingAttributes([.featureSettings: [digits]]), size: 0)
            let code = UIFont.monospacedSystemFont(ofSize: theme.inlineCodeFontSize, weight: .regular)
            inlineCodeFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: code, compatibleWith: traits)
            codeFont = Self.monospaced(UIFont.preferredFont(forTextStyle: .callout, compatibleWith: traits))
            languageFont = UIFont.preferredFont(forTextStyle: .caption1, compatibleWith: traits)
            headingFonts = (1...6).map { level in
                let spec = MarkdownStyleSpec.heading(level)
                let base = UIFont.preferredFont(forTextStyle: Self.textStyle(spec.style), compatibleWith: traits)
                let descriptor = base.fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: Self.weight(spec.weight)]])
                return UIFont(descriptor: descriptor, size: 0)
            }

            bodyColor = UIColor(theme.bodyColor)
            headingColor = UIColor(theme.headingColor)
            quoteTextColor = UIColor(theme.quoteTextColor)
            linkColor = UIColor(theme.linkColor)
            inlineCodeColor = UIColor(theme.inlineCodeColor)
            inlineCodeBackground = UIColor(theme.inlineCodeBackground)
            inlineCodeBorder = UIColor(theme.inlineCodeBorderColor)
            codeForeground = UIColor(theme.codeBlockForeground)
            codeBackground = UIColor(theme.codeBlockBackground)
            codeLanguageColor = UIColor(theme.codeLanguageColor)
            quoteBarColor = UIColor(theme.quoteBarColor)
            dividerColor = UIColor(theme.dividerColor)
            checkboxCheckedColor = UIColor(theme.checkboxCheckedColor)
            checkboxUncheckedColor = UIColor(theme.checkboxUncheckedColor)
            checkboxBorderColor = UIColor(theme.checkboxBorderColor)
            checkboxTickColor = UIColor(theme.checkboxTickColor)

            codeCornerRadius = theme.codeBlockCornerRadius
            blockSpacing = theme.blockSpacing
            nestedBlockSpacing = theme.nestedBlockSpacing
            headingTopSpacing = theme.headingTopSpacing
            checkboxSize = UIFontMetrics(forTextStyle: .body).scaledValue(for: TokenSpacing._6, compatibleWith: traits)
            checkboxBaselineOffset = UIFontMetrics(forTextStyle: .body)
                .scaledValue(for: MarkdownBlockView.checkboxBaselineOffset, compatibleWith: traits)
        }

        package static func usesDefaultFonts(_ theme: MarkdownTheme) -> Bool {
            let base = MarkdownTheme.default
            return theme.headingFonts == base.headingFonts && theme.bodyFont == base.bodyFont
                && theme.codeBlockFont == base.codeBlockFont
        }

        /// Levels outside 1...6 use the nearest one, like `MarkdownTheme.headingFont(_:)`.
        package func headingFont(_ level: Int) -> UIFont {
            headingFonts[min(max(level, 1), headingFonts.count) - 1]
        }

        // MARK: - Mapping

        /// Same as SwiftUI `.monospaced()`: the text style font with the monospaced design, so the line height stays.
        package static func monospaced(_ font: UIFont) -> UIFont {
            guard let descriptor = font.fontDescriptor.withDesign(.monospaced) else { return font }
            return UIFont(descriptor: descriptor, size: 0)
        }

        package static func textStyle(_ style: Font.TextStyle) -> UIFont.TextStyle {
            switch style {
            case .largeTitle: .largeTitle
            case .title: .title1
            case .title2: .title2
            case .title3: .title3
            case .headline: .headline
            case .subheadline: .subheadline
            case .callout: .callout
            case .footnote: .footnote
            case .caption: .caption1
            case .caption2: .caption2
            default: .body
            }
        }

        package static func weight(_ weight: Font.Weight) -> UIFont.Weight {
            switch weight {
            case .bold: .bold
            case .semibold: .semibold
            case .medium: .medium
            case .heavy: .heavy
            case .black: .black
            case .light: .light
            case .thin: .thin
            case .ultraLight: .ultraLight
            default: .regular
            }
        }
    }
}
