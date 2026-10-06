import MEGADesignToken
import SwiftUI

/// All visual styling for Markdown views.
/// The default uses MEGA design tokens for colors, spacing and corner radius.
/// Fonts are system text styles, so they follow Dynamic Type. Change fields to override:
/// ```swift
/// var theme = MarkdownTheme.default
/// theme.blockSpacing = TokenSpacing._6
/// view.markdownTheme(theme)
/// ```
/// Equatable and closure-free, so SwiftUI can tell that a theme rebuilt with the same values did not change.
public struct MarkdownTheme: Equatable, Sendable {
    /// Fonts for heading levels 1...6, in order. Read them with `headingFont(_:)`.
    public var headingFonts: [Font]
    public var headingColor: Color
    /// Extra space above a top-level heading. Separates sections.
    public var headingTopSpacing: CGFloat
    public var bodyFont: Font
    public var bodyColor: Color
    public var linkColor: Color
    /// Size of `inline code` at the default Dynamic Type size. Views scale it like body text.
    public var inlineCodeFontSize: CGFloat
    public var inlineCodeBackground: Color
    /// Border around `inline code`. SwiftUI views draw it on iOS 18 and later.
    public var inlineCodeBorderColor: Color
    public var inlineCodeColor: Color
    /// Font for fenced and indented code blocks.
    public var codeBlockFont: Font
    public var codeBlockForeground: Color
    public var codeBlockBackground: Color
    public var codeBlockCornerRadius: CGFloat
    /// Color of the language label above a fenced code block.
    public var codeLanguageColor: Color
    public var quoteBarColor: Color
    public var quoteTextColor: Color
    public var dividerColor: Color
    public var checkboxCheckedColor: Color
    public var checkboxUncheckedColor: Color
    /// Border of an unchecked checkbox.
    public var checkboxBorderColor: Color
    public var checkboxTickColor: Color
    /// Space between top-level blocks.
    public var blockSpacing: CGFloat
    /// Space between blocks inside a list item or a quote.
    public var nestedBlockSpacing: CGFloat
    public var tableHeaderBackground: Color
    public var tableAlternateRowBackground: Color
    public var tableBorderColor: Color
    public var tableCornerRadius: CGFloat
    /// Fixed width of one table column. The table scrolls sideways when it is wider than the screen.
    public var tableColumnWidth: CGFloat
    public var imageMaxHeight: CGFloat

    /// Monospaced font for `inline code`. `scale` is a `@ScaledMetric(relativeTo: .body)` of 1 in the view.
    func inlineCodeFont(scale: CGFloat) -> Font {
        .system(size: inlineCodeFontSize * scale, design: .monospaced)
    }

    /// Font for a heading level. Levels outside 1...6 use the nearest one.
    public func headingFont(_ level: Int) -> Font {
        guard !headingFonts.isEmpty else { return bodyFont }
        return headingFonts[min(max(level, 1), headingFonts.count) - 1]
    }

    public init() {
        headingFonts = (1...6).map { MarkdownStyleSpec.headingFont($0) }
        headingColor = TokenColors.Text.primary.swiftUI
        // Figma has no extra space above a heading.
        headingTopSpacing = 0
        bodyFont = .body
        bodyColor = TokenColors.Text.primary.swiftUI
        linkColor = TokenColors.Link.primary.swiftUI
        // Figma: 14. There is no font size token.
        inlineCodeFontSize = 14
        inlineCodeBackground = TokenColors.Background.surface1.swiftUI
        inlineCodeBorderColor = TokenColors.Border.strong.swiftUI
        inlineCodeColor = TokenColors.Text.brand.swiftUI
        codeBlockFont = .callout.monospaced()
        codeBlockForeground = TokenColors.Text.primary.swiftUI
        codeBlockBackground = TokenColors.Background.surface1.swiftUI
        codeBlockCornerRadius = TokenRadius.medium
        codeLanguageColor = TokenColors.Text.secondary.swiftUI
        quoteBarColor = TokenColors.Background.surface3.swiftUI
        quoteTextColor = TokenColors.Text.primary.swiftUI
        dividerColor = TokenColors.Border.subtle.swiftUI
        checkboxCheckedColor = TokenColors.Components.selectionControl.swiftUI
        checkboxUncheckedColor = TokenColors.Icon.inverse.swiftUI
        checkboxBorderColor = TokenColors.Border.strongSelected.swiftUI
        checkboxTickColor = TokenColors.Icon.inverse.swiftUI
        blockSpacing = TokenSpacing._5
        nestedBlockSpacing = TokenSpacing._2
        tableHeaderBackground = TokenColors.Background.surface2.swiftUI
        tableAlternateRowBackground = TokenColors.Background.surface1.swiftUI
        tableBorderColor = TokenColors.Border.subtle.swiftUI
        tableCornerRadius = TokenRadius.small
        tableColumnWidth = Self.defaultTableColumnWidth
        imageMaxHeight = Self.defaultImageMaxHeight
    }
}

// MARK: - Default

extension MarkdownTheme {
    /// MEGA design tokens and system text styles. Adapts to dark mode.
    public static let `default` = MarkdownTheme()

    /// Layout sizes, not spacing, so they have no design token. Same column width as Android.
    static let defaultTableColumnWidth: CGFloat = 140
    static let defaultImageMaxHeight: CGFloat = 400
}

// MARK: - Image loading

/// How Markdown images are shown.
public enum MarkdownImageLoading: Sendable {
    /// Show only the alt text. Nothing loads from the network. Same as Android.
    case altTextOnly
    /// Load the image with `AsyncImage`. Show the alt text while loading or on failure.
    case remote
    /// The host returns an image it already has, for example an icon from the app bundle.
    /// It runs while the view draws, so it must be fast. Nil shows the alt text.
    case provided(@Sendable (URL) -> UIImage?)
}

// MARK: - Environment

extension EnvironmentValues {
    @Entry var markdownTheme = MarkdownTheme.default
    @Entry var markdownImageLoading = MarkdownImageLoading.altTextOnly
    /// True inside a block quote. Paragraphs use the quote text color there.
    @Entry var markdownInQuote = false
}

// Public, so a host can set the theme and image loading above any view that shows Markdown.
// The package views read both from the environment.
extension View {
    /// Sets the theme for all Markdown views below this view.
    public func markdownTheme(_ theme: MarkdownTheme) -> some View {
        environment(\.markdownTheme, theme)
    }

    /// Sets how Markdown images load for all Markdown views below this view.
    public func markdownImageLoading(_ loading: MarkdownImageLoading) -> some View {
        environment(\.markdownImageLoading, loading)
    }
}
