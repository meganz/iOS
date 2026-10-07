import Foundation
@testable import MEGAMarkdown
import SwiftUI
import Testing
import UIKit

/// UIKit fonts and colors of a `MarkdownTheme` resolved for a trait collection.
@MainActor
@Suite struct MarkdownThemeResolvedTests {
    private let large = UITraitCollection(preferredContentSizeCategory: .large)

    /// The renderer spec written out: SwiftUI text style and weight, and the UIKit pair that must match them.
    /// Level 0 is body text.
    private static let fontTable: [Int: (Font.TextStyle, Font.Weight, UIFont.TextStyle, UIFont.Weight)] = [
        0: (.body, .regular, .body, .regular),
        1: (.title2, .bold, .title2, .bold),
        2: (.title3, .semibold, .title3, .semibold),
        3: (.headline, .semibold, .headline, .semibold),
        4: (.subheadline, .semibold, .subheadline, .semibold),
        5: (.footnote, .semibold, .footnote, .semibold),
        6: (.caption, .semibold, .caption1, .semibold)
    ]

    private static func weight(of font: UIFont) -> CGFloat? {
        let traits = font.fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
        return traits?[.weight] as? CGFloat
    }

    /// UIKit text from the resolved theme and the SwiftUI blocks use the same fonts, so both look the same.
    @Test(arguments: 0...6, [DynamicTypeSize.large, .accessibility3])
    func fontsMatchTheSwiftUITheme(level: Int, size: DynamicTypeSize) throws {
        let theme = MarkdownTheme.default
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(size))
        let style = theme.resolved(for: traits)
        let (swiftUIStyle, swiftUIWeight, uiKitStyle, uiKitWeight) = try #require(Self.fontTable[level])

        let themeFont = level == 0 ? theme.bodyFont : theme.headingFont(level)
        let expectedThemeFont: Font = level == 0 ? .body : .system(swiftUIStyle, weight: swiftUIWeight)
        #expect(themeFont == expectedThemeFont)

        let font = level == 0 ? style.bodyFont : style.headingFont(level)
        #expect(font.pointSize == UIFont.preferredFont(forTextStyle: uiKitStyle, compatibleWith: traits).pointSize)
        #expect(Self.weight(of: font) == uiKitWeight.rawValue)
    }

    /// Colors resolved for light traits still change in dark mode: a text view resolves them with its own traits.
    @Test func colorsStayDynamic() {
        let resolved = MarkdownTheme.default.resolved(for: UITraitCollection(userInterfaceStyle: .light))
        let light = UITraitCollection(userInterfaceStyle: .light)
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        for color in [resolved.bodyColor, resolved.codeBackground, resolved.dividerColor] {
            #expect(color.resolvedColor(with: light) != color.resolvedColor(with: dark))
        }
    }

    @Test func inlineCodeFontGrowsWithTheTextSize() {
        let traits = UITraitCollection(preferredContentSizeCategory: .accessibilityLarge)
        let style = MarkdownTheme.default.resolved(for: traits)
        let expected = UIFontMetrics(forTextStyle: .body).scaledValue(for: 14, compatibleWith: traits)
        // UIKit rounds a scaled font size to a whole point.
        #expect(style.inlineCodeFont.pointSize == expected.rounded())
    }

    @Test func defaultThemeUsesItsOwnFonts() {
        #expect(MarkdownTheme.default.resolved(for: large).usesThemeFonts)
    }

    @Test func customFontsFallBackToTheDefaultFonts() throws {
        var theme = MarkdownTheme.default
        theme.bodyFont = .title3
        theme.headingFonts = Array(repeating: .largeTitle, count: 6)
        theme.bodyColor = .orange
        theme.inlineCodeBackground = .yellow
        let resolved = theme.resolved(for: large)
        #expect(!resolved.usesThemeFonts)
        let defaultBody = UIFont.preferredFont(forTextStyle: .body, compatibleWith: large)
        #expect(resolved.bodyFont.pointSize == defaultBody.pointSize)
        #expect(Self.weight(of: resolved.bodyFont) == UIFont.Weight.regular.rawValue)
        #expect(resolved.headingFont(1).pointSize == UIFont.preferredFont(forTextStyle: .title2, compatibleWith: large).pointSize)
        #expect(Self.weight(of: resolved.headingFont(1)) == UIFont.Weight.bold.rawValue)
        // Colors do not depend on fonts, so the theme's own colors stay.
        #expect(resolved.bodyColor == UIColor(Color.orange))
        #expect(resolved.inlineCodeBackground == UIColor(Color.yellow))
    }
}
