import SwiftUI
import UIKit

/// Draws one `PreviewRow`: its chrome, then its content.
/// Text becomes `AttributedString` here, so only rows on screen pay for it.
/// A plain SwiftUI view: it needs no list view or cell around it.
package struct PreviewRowView: View {
    let row: PreviewRow
    let baseURL: URL?

    package init(row: PreviewRow, baseURL: URL?) {
        self.row = row
        self.baseURL = baseURL
    }

    package var body: some View {
        MarkdownRowChromeView(chrome: row.chrome, checkboxLabel: row.checkboxLabel, contentDirection: row.textDirection) {
            PreviewRowContent(row: row, baseURL: baseURL)
        }
    }
}

private struct PreviewRowContent: View {
    let row: PreviewRow
    let baseURL: URL?

    @Environment(\.markdownTheme) private var theme
    @Environment(\.markdownInQuote) private var inQuote
    @Environment(\.markdownPreviewStrings) private var strings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        switch row.content {
        case .block(let block):
            MarkdownBlockView(block: Self.markdownBlock(block, baseURL: baseURL), nested: !row.chrome.decorations.isEmpty)
        case .textPiece(let text, let headingLevel, let isFirst):
            let attributed = text.attributed(baseURL: baseURL)
            let shown = Self.withoutCutLineBreak(attributed)
            // The line gap that `Text` puts between two lines. The next piece starts the line after the break.
            let seamGap = shown.characters.count < attributed.characters.count ? lineGap(headingLevel: headingLevel) : 0
            if let headingLevel {
                let font = theme.headingFont(min(max(headingLevel, 1), 6))
                InlineTextView(text: shown, font: font, color: theme.headingColor)
                    .padding(.top, isFirst && row.chrome.decorations.isEmpty ? theme.headingTopSpacing : 0)
                    .padding(.bottom, seamGap)
                    .accessibilityAddTraits(.isHeader)
            } else {
                InlineTextView(text: shown, font: theme.bodyFont, color: inQuote ? theme.quoteTextColor : theme.bodyColor)
                    .padding(.bottom, seamGap)
            }
        case .codePiece(let language, let code, let isFirst, let isLast):
            CodeBlockView(language: language, code: code, isFirst: isFirst, isLast: isLast)
        case .tablePage(let table, let rows, let isFirst, let isLast):
            TableBlockView(
                table: Self.page(of: table, rows: rows, baseURL: baseURL),
                firstRowIndex: rows.lowerBound,
                showsHeader: isFirst,
                isFirstPage: isFirst,
                isLastPage: isLast
            )
        case .plainText(let text, let isFirst, let isLast):
            CodeBlockView(language: nil, code: text, isFirst: isFirst, isLast: isLast)
        case .notice(let notice):
            Text(notice == .shownAsPlainText ? strings.shownAsPlainText : strings.restTooLarge)
                .font(theme.bodyFont.italic())
                .foregroundStyle(theme.codeLanguageColor)
                .accessibilityIdentifier("markdown.preview.notice")
        }
    }

    /// The leading of the piece's text style at the current text size.
    /// A theme with its own fonts keeps the leading of the default style (a known limit).
    private func lineGap(headingLevel: Int?) -> CGFloat {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let style = headingLevel.map { Self.uiTextStyle(MarkdownStyleSpec.heading($0).style) } ?? .body
        return UIFont.preferredFont(forTextStyle: style, compatibleWith: traits).leading
    }

    private static func uiTextStyle(_ style: Font.TextStyle) -> UIFont.TextStyle {
        switch style {
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .footnote: .footnote
        case .caption: .caption1
        default: .body
        }
    }

    /// A piece cut after a line break ends with that break. The next row starts the new line, so the break is not
    /// drawn: `Text` would show it as an empty line at the seam. The row keeps it, for copy and line numbers.
    /// The line end of an HTML block is left to `InlineTextView`, which never draws it.
    static func withoutCutLineBreak(_ text: AttributedString) -> AttributedString {
        guard text.characters.last?.isNewline == true,
              text.runs.last?.inlinePresentationIntent?.contains(.blockHTML) != true else { return text }
        var result = text
        result.characters.removeLast()
        return result
    }

    private static func markdownBlock(_ block: ParsedBlock, baseURL: URL?) -> MarkdownBlock {
        var nextID = 0
        return block.markdownBlock(nextID: &nextID, baseURL: baseURL)
    }

    /// Converts only the page's rows, and only the columns the table view draws.
    /// The header is always kept: VoiceOver reads it with each cell.
    private static func page(of table: ParsedTable, rows: Range<Int>, baseURL: URL?) -> MarkdownTable {
        let columnCount = min(table.columns.count, TableLimits.maxColumns)
        let convert = { (cells: [InlineText]) in cells.prefix(columnCount).map { $0.attributed(baseURL: baseURL) } }
        return MarkdownTable(columns: table.columns, header: convert(table.header), rows: table.rows[rows].map(convert))
    }
}

extension PreviewRow {
    /// The checkbox's VoiceOver label: the row's text. Rows without text give an empty label.
    var checkboxLabel: String {
        switch content {
        case .block(let block):
            switch block.kind {
            case .paragraph(let text), .heading(_, let text): text.text
            default: ""
            }
        case .textPiece(let text, _, _): text.text
        case .codePiece, .tablePage, .plainText, .notice: ""
        }
    }
}

extension PreviewRow {
    /// The direction of a text row, from its first strong letter, like HTML `dir="auto"`.
    /// Nil for rows without text and text without letters: they follow the layout. Code and tables stay left to right.
    var textDirection: LayoutDirection? {
        firstStrongDirection(of: checkboxLabel)
    }
}

/// UAX #9 rules P2 and P3: the direction of the first strong letter, or nil when there is none.
/// A letter of a right-to-left script (Hebrew, Arabic, Syriac, Thaana, N'Ko and others) is right to left.
/// Any other letter is left to right. Digits, marks, spaces and punctuation are not strong.
func firstStrongDirection(of text: String) -> LayoutDirection? {
    for scalar in text.unicodeScalars {
        switch scalar.properties.generalCategory {
        case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter:
            return isRightToLeftScript(scalar) ? .rightToLeft : .leftToRight
        default:
            continue
        }
    }
    return nil
}

/// The Unicode blocks of right-to-left scripts.
private func isRightToLeftScript(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar.value {
    case 0x0590...0x08FF, 0xFB1D...0xFDFF, 0xFE70...0xFEFF, 0x10800...0x10FFF, 0x1E800...0x1EFFF: true
    default: false
    }
}
