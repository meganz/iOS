import MEGADesignToken
import MEGAMarkdown
import SwiftUI

/// One list item of the rich editor: the shared row chrome around an editable text, a divider or a raw block piece.
struct RichRowView: View {
    enum Content {
        /// A text or code row. `version` is the model version the block was read at.
        case text(RichBlock, id: RichRowID, version: Int)
        case divider
        /// One preview row of a raw block, drawn read-only like the preview.
        case rawPiece(PreviewRow)
        /// A raw block that renders nothing (definitions only, blank). Its source shows dimmed.
        case rawSource(String)
    }

    let content: Content
    let chrome: MarkdownRowChrome
    /// An atomic row (divider or raw block) that the selection covers. The selection layer draws its highlight.
    /// The row only tells VoiceOver.
    let isSelected: Bool
    let theme: MarkdownTheme
    let strings: MarkdownEditorStrings
    let baseURL: URL?
    weak var host: (any RichTextRowHost)?
    let onToggleCheckbox: (() -> Void)?
    let onSelectAtomic: (() -> Void)?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.legibilityWeight) private var legibilityWeight

    var body: some View {
        Group {
            switch content {
            case .rawPiece(let row):
                atomic(PreviewRowView(row: row, baseURL: baseURL))
            default:
                MarkdownRowChromeView(chrome: chrome, checkboxLabel: checkboxLabel, onToggle: onToggleCheckbox, contentDirection: textDirection) {
                    inner
                }
            }
        }
        // Rows never animate: a change of the checkbox, marker or gap shows at once.
        .transaction { $0.animation = nil }
    }

    /// The direction of the row's own text, so its list marker and checkbox sit on the side where the text starts.
    /// The same rule aligns the text in `RichTextStyler`. Nil for code and rows without text: they follow the layout.
    private var textDirection: LayoutDirection? {
        guard case .text(let block, _, _) = content, let text = block.richText?.text else { return nil }
        switch RichTextStyler.writingDirection(of: text) {
        case .rightToLeft: return .rightToLeft
        case .leftToRight: return .leftToRight
        default: return nil
        }
    }

    @ViewBuilder
    private var inner: some View {
        switch content {
        case .text(let block, let id, let version):
            textRow(block, id: id, version: version)
        case .divider:
            atomic(MarkdownDivider(nested: !chrome.decorations.isEmpty))
        case .rawSource(let source):
            atomic(
                Text(verbatim: source)
                    .font(theme.bodyFont)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        case .rawPiece:
            EmptyView()
        }
    }

    @ViewBuilder
    private func textRow(_ block: RichBlock, id: RichRowID, version: Int) -> some View {
        // The text view has room on each side for the inline code chip. The text stays at the row's edges.
        let row = RichTextRow(block: block, version: version, id: id, theme: theme, strings: strings, host: host)
            .padding(.horizontal, -InlineCodeLayoutManager.chipPadding)
        let firstBaseline = baseline(block)
        switch block {
        case .codeBlock(let language, _):
            // The frame leaves the side padding to its content, like the preview's code block.
            CodeBlockFrame(language: language, isFirst: true, isLast: true) { row.padding(.horizontal, TokenSpacing._4) }
        case .heading:
            row
                .alignmentGuide(.firstTextBaseline) { _ in firstBaseline }
                .padding(.top, chrome.decorations.isEmpty ? theme.headingTopSpacing : 0)
        default:
            row.alignmentGuide(.firstTextBaseline) { _ in firstBaseline }
        }
    }

    /// The list marker lines up with the text's first baseline. A text view gives SwiftUI no baseline.
    private func baseline(_ block: RichBlock) -> CGFloat {
        let traits = UITraitCollection { traits in
            traits.preferredContentSizeCategory = UIContentSizeCategory(dynamicTypeSize)
            traits.legibilityWeight = legibilityWeight == .bold ? .bold : .regular
        }
        return RichTextRow.firstBaseline(of: block, theme: theme, traits: traits)
    }

    /// A divider or raw piece takes a tap as a selection of the whole block. Links in it do not open.
    private func atomic(_ view: some View) -> some View {
        view
            .environment(\.openURL, OpenURLAction { _ in .handled })
            .contentShape(Rectangle())
            .onTapGesture { onSelectAtomic?() }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var checkboxLabel: String {
        if case .text(let block, _, _) = content { block.richText?.text ?? "" } else { "" }
    }
}
