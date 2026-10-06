import MEGADesignToken
import SwiftUI

/// Draws a row's quote bars, list marker columns and gap below, with the content inside.
/// Only the checkbox takes taps, so a text view in the content gets every other touch.
package struct MarkdownRowChromeView<Content: View>: View {
    let chrome: MarkdownRowChrome
    let checkboxLabel: String
    let onToggle: (() -> Void)?
    let contentDirection: LayoutDirection?
    let content: Content

    @Environment(\.markdownTheme) private var theme

    /// `checkboxLabel` is the VoiceOver label of a checkbox marker. `onToggle` nil: the checkbox only shows its state.
    /// `contentDirection` is the direction of the row's own text. Its list, from the outermost level inside its
    /// innermost quote, and the content follow it, so nested markers indent from the text's side.
    /// Quote bars follow the layout. Nil: everything follows the layout.
    package init(
        chrome: MarkdownRowChrome,
        checkboxLabel: String,
        onToggle: (() -> Void)? = nil,
        contentDirection: LayoutDirection? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.chrome = chrome
        self.checkboxLabel = checkboxLabel
        self.onToggle = onToggle
        self.contentDirection = contentDirection
        self.content = content()
    }

    package var body: some View {
        let gap = chrome.gapSpacing(blockSpacing: theme.blockSpacing, nestedSpacing: theme.nestedBlockSpacing)
        DecoratedRowContent(
            chrome: chrome,
            decorations: chrome.decorations.prefix(MarkdownRowChrome.maxVisibleNesting),
            checkboxLabel: checkboxLabel,
            onToggle: onToggle,
            innerGap: gap.inner,
            contentDirection: contentDirection,
            directionLevel: directionLevel,
            content: content
        )
        // A cell can be up to 1 pt taller than its content. A quote bar that goes on below fills that space too.
        // Other rows keep their place in the cell.
        .frame(maxHeight: quoteGoesOn ? .infinity : nil, alignment: .top)
        .padding(.bottom, gap.outer)
    }

    /// The outermost list level after the row's last quote. The content direction starts there, so all list columns
    /// of the row's list mirror together. Nil when the row is in no list.
    private var directionLevel: Int? {
        var level: Int?
        for (index, decoration) in chrome.decorations.prefix(MarkdownRowChrome.maxVisibleNesting).enumerated() {
            switch decoration {
            case .quote: level = nil
            case .listItem: if level == nil { level = index }
            }
        }
        return level
    }

    /// True when a quote of this row goes on in the next row.
    private var quoteGoesOn: Bool {
        chrome.decorations.prefix(MarkdownRowChrome.maxVisibleNesting).enumerated().contains { level, decoration in
            if case .quote = decoration { return !chrome.quoteBarEnds(level: level).bottom }
            return false
        }
    }
}

/// One decoration level, then the rest. Recursive, at most `MarkdownRowChrome.maxVisibleNesting` levels.
private struct DecoratedRowContent<Content: View>: View {
    let chrome: MarkdownRowChrome
    let decorations: ArraySlice<MarkdownRowDecoration>
    let checkboxLabel: String
    let onToggle: (() -> Void)?
    let innerGap: CGFloat
    let contentDirection: LayoutDirection?
    /// The list level where `contentDirection` starts, or nil to start it at the content.
    let directionLevel: Int?
    let content: Content

    @Environment(\.markdownTheme) private var theme

    var body: some View {
        if let first = decorations.first {
            let rest = DecoratedRowContent(
                chrome: chrome, decorations: decorations.dropFirst(), checkboxLabel: checkboxLabel, onToggle: onToggle,
                innerGap: innerGap, contentDirection: contentDirection, directionLevel: directionLevel, content: content
            )
            let columnGap = decorations.startIndex == chrome.gapColumn ? innerGap : 0
            switch first {
            case .quote:
                // Same bar and spacing as `QuoteBlockView`. Only the quote's first and last rows round the bar ends.
                let ends = chrome.quoteBarEnds(level: decorations.startIndex)
                let radius = MarkdownStyleSpec.quoteBarRadius
                let bar = UnevenRoundedRectangle(
                    topLeadingRadius: ends.top ? radius : 0,
                    bottomLeadingRadius: ends.bottom ? radius : 0,
                    bottomTrailingRadius: ends.bottom ? radius : 0,
                    topTrailingRadius: ends.top ? radius : 0
                )
                    .fill(theme.quoteBarColor)
                    .frame(width: MarkdownStyleSpec.quoteBarWidth)
                let column = HStack(alignment: .top, spacing: TokenSpacing._3) {
                    // Room for the bar, which is drawn as the background. No height, so the column is as tall as its content.
                    Color.clear.frame(width: MarkdownStyleSpec.quoteBarWidth, height: 0)
                    rest
                }
                Group {
                    if ends.bottom {
                        column
                            .background(alignment: .leading) { bar }
                            .padding(.bottom, columnGap)
                    } else {
                        // The quote goes on in the next row, so the bar fills this row to its bottom edge, gaps included.
                        // It reaches 1 pt into the next cell: a cell edge between two pixels would leave a light line.
                        // One bar then runs through the whole quote, like Android and GitHub.
                        column
                            .padding(.bottom, columnGap)
                            .frame(maxHeight: .infinity, alignment: .top)
                            .background(alignment: .leading) { bar.padding(.bottom, -1) }
                    }
                }
                .environment(\.markdownInQuote, true)
            case .listItem(let marker, let showsMarker):
                // Same marker column as `ListBlockView`. A hidden marker keeps the width on the item's later rows.
                // Figma: 4 from a checkbox to its text, 8 after a bullet or number.
                HStack(alignment: .firstTextBaseline, spacing: marker.isCheckbox ? TokenSpacing._2 : TokenSpacing._3) {
                    ListMarkerView(marker: marker, label: checkboxLabel, onToggle: showsMarker ? onToggle : nil)
                        .opacity(showsMarker ? 1 : 0)
                        .accessibilityHidden(!showsMarker)
                    rest
                }
                .padding(.bottom, columnGap)
                .contentLayoutDirection(decorations.startIndex == directionLevel ? contentDirection : nil)
            }
        } else if chrome.decorations.count > MarkdownRowChrome.maxVisibleNesting {
            // Deeper levels are not indented any more. This marker shows that some are hidden.
            HStack(alignment: .firstTextBaseline, spacing: TokenSpacing._2) {
                Text(verbatim: "…")
                    .font(theme.bodyFont)
                    .foregroundStyle(theme.quoteBarColor)
                    .accessibilityHidden(true)
                paddedContent
            }
            .contentLayoutDirection(directionLevel == nil ? contentDirection : nil)
        } else {
            paddedContent
                .contentLayoutDirection(directionLevel == nil ? contentDirection : nil)
        }
    }

    /// A gap that belongs to no column sits below the content.
    private var paddedContent: some View {
        content
            .padding(.bottom, chrome.gapColumn == nil ? innerGap : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension View {
    /// Sets the layout direction when `direction` is not nil.
    func contentLayoutDirection(_ direction: LayoutDirection?) -> some View {
        transformEnvironment(\.layoutDirection) { value in
            if let direction { value = direction }
        }
    }
}
