import MEGADesignToken
import SwiftUI
import UIKit

/// GFM table. Columns have a fixed width, like Android, so wide tables scroll sideways.
struct TableBlockView: View {
    let table: MarkdownTable
    /// Index of `table.rows[0]` in the whole table. A big table is drawn as several pages;
    /// the stripes must follow the whole table, not the page.
    var firstRowIndex = 0
    var showsHeader = true
    var isFirstPage = true
    var isLastPage = true

    @Environment(\.markdownTheme) private var theme
    /// The column width grows with Dynamic Type, so large text does not break words in the middle.
    @ScaledMetric(relativeTo: .body) private var columnWidthScale: CGFloat = 1
    @ScaledMetric(relativeTo: .body) private var codeScale: CGFloat = 1
    /// Header text ascent at the default body size. It scales with the text size.
    @ScaledMetric(relativeTo: .body) private var headerAscent = UIFont.preferredFont(
        forTextStyle: .body,
        compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
    ).ascender

    /// Columns after `TableLimits.maxColumns` are not drawn. A "…" column shows they exist.
    private var shownColumns: [(offset: Int, element: MarkdownTable.Column)] {
        Array(table.columns.enumerated().prefix(TableLimits.maxColumns))
    }

    private var hasHiddenColumns: Bool {
        table.columns.count > TableLimits.maxColumns
    }

    var body: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: isFirstPage ? theme.tableCornerRadius : 0,
            bottomLeadingRadius: isLastPage ? theme.tableCornerRadius : 0,
            bottomTrailingRadius: isLastPage ? theme.tableCornerRadius : 0,
            topTrailingRadius: isFirstPage ? theme.tableCornerRadius : 0
        )
        ScrollView(.horizontal) {
            Grid(alignment: .topLeading, horizontalSpacing: 0, verticalSpacing: 0) {
                if showsHeader {
                    GridRow {
                        ForEach(shownColumns, id: \.offset) { index, column in
                            cell(Self.capped(headerText(at: index)), alignment: column.alignment, isHeader: true)
                                .background(theme.tableHeaderBackground)
                                .accessibilityAddTraits(.isHeader)
                        }
                        if hasHiddenColumns {
                            cell(AttributedString("…"), alignment: .none, isHeader: true)
                                .background(theme.tableHeaderBackground)
                        }
                    }
                }
                ForEach(Array(table.rows.enumerated()), id: \.offset) { offset, row in
                    let rowIndex = firstRowIndex + offset
                    GridRow {
                        ForEach(shownColumns, id: \.offset) { index, column in
                            let text = Self.capped(index < row.count ? row[index] : AttributedString())
                            cell(text, alignment: column.alignment, isHeader: false)
                                .background(rowIndex.isMultiple(of: 2) ? Color.clear : theme.tableAlternateRowBackground)
                                .accessibilityLabel(Text(Self.capped(headerText(at: index))) + Text(verbatim: ": ") + Text(text))
                        }
                        if hasHiddenColumns {
                            cell(AttributedString("…"), alignment: .none, isHeader: false)
                                .background(rowIndex.isMultiple(of: 2) ? Color.clear : theme.tableAlternateRowBackground)
                        }
                    }
                }
            }
            // Rows size to their tallest cell. Cells then stretch to the row height, so borders line up.
            .fixedSize(horizontal: false, vertical: true)
            .clipShape(shape)
            .overlay(shape.stroke(theme.tableBorderColor, lineWidth: Self.outerBorderWidth))
        }
        // A lazy container can propose a cached height. Without this the table takes it and clips rows.
        .fixedSize(horizontal: false, vertical: true)
        // Columns run left to right in every layout, like GitHub. A right-to-left word still reads right to left.
        .environment(\.layoutDirection, .leftToRight)
        // A scroll view has no text baseline, so a list marker would sit at the bottom edge.
        // The first baseline is the text baseline of the first row.
        // The guide closure is Sendable, so it takes a copy of the main-actor value.
        .alignmentGuide(.firstTextBaseline) { [offset = TokenSpacing._3 + headerAscent] in $0[.top] + offset }
    }

    private func headerText(at index: Int) -> AttributedString {
        index < table.header.count ? table.header[index] : AttributedString()
    }

    /// `text` must already be `capped`.
    private func cell(_ text: AttributedString, alignment: MarkdownTable.Alignment, isHeader: Bool) -> some View {
        let codeOffset = theme.inlineCodeBaselineOffset(scale: codeScale)
        return inlineText(theme.styledInline(text, codeFont: theme.inlineCodeFont(scale: codeScale), codeBaselineOffset: codeOffset))
            .font(isHeader ? theme.bodyFont.bold() : theme.bodyFont)
            .foregroundStyle(theme.bodyColor)
            .tint(theme.linkColor)
            .inlineCodeChips(theme, for: text, scale: codeScale)
            .multilineTextAlignment(textAlignment(alignment))
            .fixedSize(horizontal: false, vertical: true)
            .padding(TokenSpacing._3)
            .frame(width: theme.tableColumnWidth * columnWidthScale, alignment: frameAlignment(alignment))
            .frame(maxHeight: .infinity, alignment: frameAlignment(alignment))
            .border(theme.tableBorderColor, width: Self.cellBorderWidth)
    }

    /// Long cell text is cut and ends with "…", so one cell cannot freeze the layout.
    static func capped(_ text: AttributedString) -> AttributedString {
        let characters = text.characters
        guard let end = characters.index(characters.startIndex, offsetBy: TableLimits.maxCellCharacters, limitedBy: characters.endIndex),
              end < characters.endIndex else { return text }
        var result = AttributedString(text[characters.startIndex..<end])
        result += AttributedString("…")
        return result
    }

    /// Explicit `.left` and `.right` are physical sides, like `align="left"` in cmark's HTML.
    /// The table is always laid out left to right, so leading is left. `.none` is left too.
    private func isLeading(_ alignment: MarkdownTable.Alignment) -> Bool {
        switch alignment {
        case .none, .left: true
        case .right, .center: false
        }
    }

    private func textAlignment(_ alignment: MarkdownTable.Alignment) -> TextAlignment {
        if alignment == .center { return .center }
        return isLeading(alignment) ? .leading : .trailing
    }

    private func frameAlignment(_ alignment: MarkdownTable.Alignment) -> Alignment {
        if alignment == .center { return .top }
        return isLeading(alignment) ? .topLeading : .topTrailing
    }

    // No design token for border width.
    private static let outerBorderWidth: CGFloat = 1
    private static let cellBorderWidth: CGFloat = 0.5
}
