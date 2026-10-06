import MEGADesignToken
import SwiftUI

/// Draws one block. Container blocks draw their children with this view again.
/// The switch has no `default`: a new `MarkdownBlock.Kind` case fails to compile until it has a view.
struct MarkdownBlockView: View {
    let block: MarkdownBlock
    /// True inside a list item or a quote. Nested blocks get no extra heading space.
    var nested = false

    @Environment(\.markdownTheme) private var theme
    @Environment(\.markdownInQuote) private var inQuote

    var body: some View {
        switch block.kind {
        case .heading(let level, let text):
            InlineTextView(text: text, font: theme.headingFont(min(max(level, 1), 6)), color: theme.headingColor)
                .padding(.top, nested ? 0 : theme.headingTopSpacing)
                .accessibilityAddTraits(.isHeader)
        case .paragraph(let text):
            InlineTextView(text: text, font: theme.bodyFont, color: inQuote ? theme.quoteTextColor : theme.bodyColor)
        case .list(let list):
            ListBlockView(list: list)
        case .codeBlock(let language, let code):
            CodeBlockView(language: language, code: code)
        case .blockQuote(let children):
            QuoteBlockView(children: children)
        case .table(let table):
            TableBlockView(table: table)
        case .thematicBreak:
            MarkdownDivider(nested: nested)
        case .image(let url, let altText):
            ImageBlockView(url: url, altText: altText)
        }
    }

    // No design token for these. Internal, so other views can use them.
    nonisolated static let dividerHeight: CGFloat = 1
    /// Puts the checkbox centre near the body x-height, at the default body size.
    /// It scales with the text size, like the box, so the box stays on the first line.
    nonisolated static let checkboxBaselineOffset: CGFloat = 5
}

// MARK: - List

struct ListBlockView: View {
    let list: MarkdownList

    @Environment(\.markdownTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(list.items.enumerated()), id: \.offset) { index, item in
                // Figma: 4 from a checkbox to its text, 8 after a bullet or number.
                HStack(alignment: .firstTextBaseline, spacing: item.checkbox == nil ? TokenSpacing._3 : TokenSpacing._2) {
                    marker(index: index, item: item)
                    VStack(alignment: .leading, spacing: theme.nestedBlockSpacing) {
                        ForEach(item.blocks) { child in
                            MarkdownBlockView(block: child, nested: true)
                        }
                    }
                }
                .padding(.top, index == 0 ? 0 : Self.itemPadding(item))
                .padding(.bottom, index == list.items.count - 1 ? 0 : Self.itemPadding(item))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Figma: 8 between two task items, 0 between other items. Each task item pads its own edges
    /// by this, so a task item next to another item is 4 away. Split preview rows use the same value.
    nonisolated static let taskItemPadding = TokenSpacing._2

    private static func itemPadding(_ item: MarkdownListItem) -> CGFloat {
        item.checkbox == nil ? 0 : taskItemPadding
    }

    private func marker(index: Int, item: MarkdownListItem) -> some View {
        let marker: MarkdownListMarker
        if let checkbox = item.checkbox {
            marker = .checkbox(isChecked: checkbox == .checked)
        } else if list.isOrdered {
            marker = .number(list.startIndex + index)
        } else {
            marker = .bullet
        }
        return ListMarkerView(marker: marker, label: item.taskLabel)
    }
}

extension MarkdownListItem {
    /// Plain text of the item's first text block. Used as the checkbox label for VoiceOver.
    var taskLabel: String {
        for block in blocks {
            switch block.kind {
            case .paragraph(let text), .heading(_, let text):
                return String(text.characters)
            default:
                continue
            }
        }
        return ""
    }
}

// MARK: - Code block

struct CodeBlockView: View {
    let language: String?
    let code: String
    /// A big code block is drawn as several pieces. Only the first and last piece get the outer padding and corners.
    var isFirst = true
    var isLast = true

    @Environment(\.markdownTheme) private var theme

    var body: some View {
        let pieces = splitForMeasuring(AttributedString(code))
        CodeBlockFrame(language: language, isFirst: isFirst, isLast: isLast) {
            // A scroll view hides the baseline of its text. The hidden line has the baseline of the first code line,
            // so a list marker next to the box lines up with that line.
            ZStack(alignment: .topLeading) {
                Text(verbatim: " ")
                    .font(theme.codeBlockFont)
                    .hidden()
                    .accessibilityHidden(true)
                codeScrollView(pieces)
            }
        }
    }

    private func codeScrollView(_ pieces: [AttributedString]) -> some View {
        // The side padding sits inside the scroll view, so long lines scroll up to the box edge.
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 0) {
                // Same as `InlineTextView`: one piece needs no `ForEach`.
                if pieces.count == 1 {
                    Text(pieces[0])
                } else {
                    ForEach(Array(pieces.enumerated()), id: \.offset) { _, piece in
                        Text(piece)
                    }
                }
            }
            .font(theme.codeBlockFont)
            .foregroundStyle(theme.codeBlockForeground)
            // A horizontal scroll view can propose less height than the lines need. The text then cut its last line with "…".
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, TokenSpacing._4)
        }
    }
}

// MARK: - Quote

struct QuoteBlockView: View {
    let children: [MarkdownBlock]

    @Environment(\.markdownTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: TokenSpacing._3) {
            RoundedRectangle(cornerRadius: MarkdownStyleSpec.quoteBarRadius)
                .fill(theme.quoteBarColor)
                .frame(width: MarkdownStyleSpec.quoteBarWidth)
            VStack(alignment: .leading, spacing: theme.nestedBlockSpacing) {
                ForEach(children) { child in
                    MarkdownBlockView(block: child, nested: true)
                }
            }
            .environment(\.markdownInQuote, true)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Image

struct ImageBlockView: View {
    let url: URL?
    let altText: String

    @Environment(\.markdownTheme) private var theme
    @Environment(\.markdownImageLoading) private var loading

    var body: some View {
        switch loading {
        case .remote where url != nil:
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    imageView(image)
                } else {
                    altTextView
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .provided(let provide):
            if let url, let image = provide(url) {
                imageView(Image(uiImage: image))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                altTextView
            }
        case .remote, .altTextOnly:
            altTextView
        }
    }

    private func imageView(_ image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: theme.imageMaxHeight, alignment: .leading)
            // A max-height frame alone takes all the height it is offered. This keeps the image's own height.
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(altText)
            // No alt text: VoiceOver would say only "image", so treat it as decoration.
            .accessibilityHidden(altText.isEmpty)
    }

    private var altTextView: some View {
        Text(altText)
            .font(theme.bodyFont)
            .foregroundStyle(theme.bodyColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
