import MEGADesignToken
@testable import MEGAMarkdown
import SwiftUI
import Testing
import UIKit

@Suite struct StyleSpecTests {
    /// Heading styles of the Figma heading menu. H4 to H6 are not designed, so they stay below H3.
    @Test func headingTableMatchesFigma() {
        let table = (1...7).map { MarkdownStyleSpec.heading($0) }
        #expect(table.map(\.style) == [.title2, .title3, .headline, .subheadline, .footnote, .caption, .caption])
        #expect(table.map(\.weight) == [.bold, .semibold, .semibold, .semibold, .semibold, .semibold, .semibold])
    }

    @Test func themeHeadingFontUsesTheSpec() {
        let theme = MarkdownTheme.default
        for level in 1...6 {
            #expect(theme.headingFont(level) == MarkdownStyleSpec.headingFont(level))
        }
        #expect(MarkdownStyleSpec.headingFont(1) == .system(.title2, weight: .bold))
    }

    /// Figma tokens: quote bar surface 3 with primary text, checkbox inverse fill with a strong selected border.
    @Test func themeDefaultsMatchFigmaTokens() {
        let theme = MarkdownTheme.default
        #expect(theme.quoteBarColor == TokenColors.Background.surface3.swiftUI)
        #expect(theme.quoteTextColor == TokenColors.Text.primary.swiftUI)
        #expect(theme.checkboxCheckedColor == TokenColors.Components.selectionControl.swiftUI)
        #expect(theme.checkboxUncheckedColor == TokenColors.Icon.inverse.swiftUI)
        #expect(theme.checkboxBorderColor == TokenColors.Border.strongSelected.swiftUI)
        #expect(theme.checkboxTickColor == TokenColors.Icon.inverse.swiftUI)
        #expect(theme.inlineCodeColor == TokenColors.Text.brand.swiftUI)
        #expect(MarkdownStyleSpec.quoteBarWidth == 4)
        #expect(MarkdownStyleSpec.quoteBarRadius == 2)
    }

    /// The tick stays inside the box, round caps included.
    @Test func tickPathFitsInsideTheBox() {
        let box = CGRect(x: 0, y: 0, width: 16, height: 16)
        let bounds = MarkdownCheckmark().path(in: box).boundingRect
        #expect(bounds == CGRect(x: 3.5, y: 5, width: 9, height: 6.5))
        #expect(box.insetBy(dx: 0.75, dy: 0.75).contains(bounds))
    }

    // MARK: - Contrast

    /// WCAG 2.1 AA: normal text needs at least 4.5:1 on its background, in light and dark mode.
    /// The pairs are the text and background tokens of the default theme.
    @Test func textColoursMeetContrastMinimum() {
        let pairs: [(name: String, text: UIColor, background: UIColor)] = [
            ("body text", TokenColors.Text.primary, TokenColors.Background.page),
            ("link", TokenColors.Link.primary, TokenColors.Background.page),
            ("inline code", TokenColors.Text.brand, TokenColors.Background.surface1),
            ("code block", TokenColors.Text.primary, TokenColors.Background.surface1),
            ("code language", TokenColors.Text.secondary, TokenColors.Background.surface1),
            ("table header", TokenColors.Text.primary, TokenColors.Background.surface2)
        ]
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            for pair in pairs {
                let text = pair.text.resolvedColor(with: traits)
                let background = pair.background.resolvedColor(with: traits)
                // The ratio is only valid for opaque colours. A see-through token needs a blend first.
                #expect(Self.alpha(text) == 1 && Self.alpha(background) == 1, "\(pair.name) is not opaque")
                let ratio = Self.contrastRatio(text, background)
                let comment = Comment(rawValue: "\(pair.name), \(style == .dark ? "dark" : "light"): \(ratio)")
                if pair.name == "inline code" && style == .dark {
                    withKnownIssue(Self.darkInlineCodeIssue) {
                        #expect(ratio >= 4.5, comment)
                    }
                } else {
                    #expect(ratio >= 4.5, comment)
                }
            }
        }
    }

    /// Guards the contrast math above: known WCAG values, in any order.
    @Test func contrastRatioMatchesKnownWCAGValues() {
        #expect(abs(Self.contrastRatio(.black, .white) - 21) < 0.001)
        #expect(abs(Self.contrastRatio(.white, .black) - 21) < 0.001)
        #expect(abs(Self.contrastRatio(.white, .white) - 1) < 0.001)
        // #767676 on white is the darkest grey that is just above 4.5:1.
        let grey = UIColor(red: 118 / 255, green: 118 / 255, blue: 118 / 255, alpha: 1)
        #expect(abs(Self.contrastRatio(grey, .white) - 4.54) < 0.01)
        #expect(Self.contrastRatio(UIColor(white: 0.5, alpha: 1), .white) < 4.5)
    }

    /// The contrast test checks token pairs. This proves the default theme really draws text with those pairs.
    @Test func contrastPairsAreTheDefaultThemeColours() {
        let theme = MarkdownTheme.default
        #expect(theme.bodyColor == TokenColors.Text.primary.swiftUI)
        #expect(theme.headingColor == TokenColors.Text.primary.swiftUI)
        #expect(theme.quoteTextColor == TokenColors.Text.primary.swiftUI)
        #expect(theme.linkColor == TokenColors.Link.primary.swiftUI)
        #expect(theme.inlineCodeColor == TokenColors.Text.brand.swiftUI)
        #expect(theme.inlineCodeBackground == TokenColors.Background.surface1.swiftUI)
        #expect(theme.codeBlockForeground == TokenColors.Text.primary.swiftUI)
        #expect(theme.codeBlockBackground == TokenColors.Background.surface1.swiftUI)
        #expect(theme.codeLanguageColor == TokenColors.Text.secondary.swiftUI)
        #expect(theme.tableHeaderBackground == TokenColors.Background.surface2.swiftUI)
        #expect(theme.tableAlternateRowBackground == TokenColors.Background.surface1.swiftUI)
        // If light and dark resolved to the same colour, the dark pass would test nothing new.
        let light = UITraitCollection(userInterfaceStyle: .light)
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        for token in [TokenColors.Text.primary, TokenColors.Background.page, TokenColors.Text.brand, TokenColors.Background.surface1] {
            #expect(token.resolvedColor(with: light) != token.resolvedColor(with: dark))
        }
    }

    /// Table cells draw links on the header fill and on the striped rows, not only on the page.
    @Test func linkOnTableBackgroundsMeetsContrastMinimum() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let link = TokenColors.Link.primary.resolvedColor(with: traits)
            for (name, background) in [("header", TokenColors.Background.surface2), ("striped row", TokenColors.Background.surface1)] {
                let ratio = Self.contrastRatio(link, background.resolvedColor(with: traits))
                #expect(ratio >= 4.5, "link on table \(name), \(style == .dark ? "dark" : "light"): \(ratio)")
            }
        }
    }

    /// WCAG 2.1 AA 1.4.11: the parts that show a task's state need 3:1 against what is next to them.
    @Test func checkboxMeetsNonTextContrastMinimum() {
        let theme = MarkdownTheme.default
        #expect(theme.checkboxBorderColor == TokenColors.Border.strongSelected.swiftUI)
        #expect(theme.checkboxCheckedColor == TokenColors.Components.selectionControl.swiftUI)
        #expect(theme.checkboxTickColor == TokenColors.Icon.inverse.swiftUI)
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let page = TokenColors.Background.page.resolvedColor(with: traits)
            let checked = TokenColors.Components.selectionControl.resolvedColor(with: traits)
            let checks: [(name: String, ratio: CGFloat)] = [
                ("unchecked border on page", Self.contrastRatio(TokenColors.Border.strongSelected.resolvedColor(with: traits), page)),
                ("checked fill on page", Self.contrastRatio(checked, page)),
                ("tick on checked fill", Self.contrastRatio(TokenColors.Icon.inverse.resolvedColor(with: traits), checked))
            ]
            for check in checks {
                #expect(check.ratio >= 3, "\(check.name), \(style == .dark ? "dark" : "light"): \(check.ratio)")
            }
        }
    }

    /// Levels outside 1...6 use the nearest level. A theme with no heading fonts uses the body font.
    @Test func headingFontOutsideOneToSixUsesTheNearestLevel() {
        let theme = MarkdownTheme.default
        #expect(theme.headingFont(0) == theme.headingFont(1))
        #expect(theme.headingFont(-3) == theme.headingFont(1))
        #expect(theme.headingFont(7) == theme.headingFont(6))
        #expect(theme.headingFont(99) == theme.headingFont(6))
        #expect(theme.headingFont(1) != theme.headingFont(6))
        var empty = MarkdownTheme.default
        empty.headingFonts = []
        #expect(empty.headingFont(1) == empty.bodyFont)
    }

    private static let darkInlineCodeIssue: Comment =
        "Inline code: Text.brand on Background.surface1 is below 4.5:1 in dark mode. The design team keeps the Figma tokens."

    private static func contrastRatio(_ first: UIColor, _ second: UIColor) -> CGFloat {
        let (lighter, darker) = (max(luminance(first), luminance(second)), min(luminance(first), luminance(second)))
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func alpha(_ color: UIColor) -> CGFloat {
        color.cgColor.alpha
    }

    /// WCAG relative luminance of an sRGB color.
    private static func luminance(_ color: UIColor) -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func linear(_ value: CGFloat) -> CGFloat {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}
