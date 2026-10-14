import Foundation

/// What a copy puts on the pasteboard: one item with two types.
/// Other apps read the plain text. The editors read the Markdown first.
struct RichClipboardContent: Equatable, Sendable {
    /// The pasteboard type of `markdown`.
    static let markdownType = "net.daringfireball.markdown"
    /// A private pasteboard type with no data. It marks a part of a code block, see `isCodePart`.
    static let codePartType = "nz.mega.markdown.code-part"

    /// The visible text: no Markdown syntax and no escapes. List items keep a `- `, `1. ` or `- [ ] ` marker.
    var plainText: String
    /// The Markdown of the selection.
    var markdown: String
    /// A part of a code block. Its Markdown is escaped for a text block, so source mode pastes the plain text:
    /// CommonMark reads no escapes in a code block, so they would stay in the code there.
    var isCodePart = false
}

/// What a paste reads from the pasteboard. Either can be missing.
struct RichPasteContent: Equatable, Sendable {
    var markdown: String?
    var plainText: String?

    init(markdown: String? = nil, plainText: String? = nil) {
        self.markdown = markdown
        self.plainText = plainText
    }
}

/// Copy and paste rules. Pure functions of the document.
enum RichClipboard {
    /// The clipboard content of a selection. nil for a caret.
    /// A part of one block copies as inline Markdown without the block syntax, so it pastes into any block.
    /// A whole block or more copies as block Markdown (`## `, `- [ ] `, `3. `, fences).
    static func content(of document: RichDocument, in selection: RichSelection) -> RichClipboardContent? {
        let selection = document.clamped(selection)
        guard !selection.isCaret else { return nil }
        if let range = selection.rangeInBlock, let text = document.blocks[selection.start.blockIndex].richText, range.count < text.length {
            let slice = text.slice(range)
            return RichClipboardContent(plainText: visibleText(slice), markdown: InlineWriter.write(slice, context: .paragraph).markdown)
        }
        if let range = selection.rangeInBlock, let code = document.blocks[selection.start.blockIndex].codeText, range.count < code.utf16.count {
            let part = code.substring(utf16: range)
            // Code has no Markdown syntax. Escaped, it pastes into a text block as the same text.
            let markdown = InlineWriter.write(RichText(part), context: .paragraph).markdown
            return RichClipboardContent(plainText: part, markdown: markdown, isCodePart: true)
        }
        let fragment = document.fragment(in: selection)
        guard !fragment.isEmpty else { return nil }
        return RichClipboardContent(
            plainText: plainText(of: fragment),
            markdown: RichMarkdownConverter.markdownFragment(from: fragment)
        )
    }

    /// The blocks a paste inserts into a text block. The Markdown type wins over plain text.
    /// Plain text from another app is read as Markdown too, so pasted syntax renders.
    /// Its soft breaks split paragraphs, so each pasted line becomes a row, like typing it would.
    static func blocks(from content: RichPasteContent) -> [RichBlock] {
        if let markdown = content.markdown, !markdown.isEmpty {
            return restoringEdgeSpaces(RichMarkdownConverter.document(from: markdown).blocks, plainText: content.plainText)
        }
        guard let plain = content.plainText, !plain.isEmpty else { return [] }
        return RichMarkdownConverter.document(from: plain).blocks.flatMap(splittingSoftBreaks)
    }

    /// The text a paste inserts into a code block: plain text first, as code is plain.
    static func codeText(from content: RichPasteContent) -> String {
        content.plainText ?? content.markdown ?? ""
    }

    // MARK: - Helpers

    /// One paragraph per line of a paragraph with soft breaks. Other blocks stay as they are.
    private static func splittingSoftBreaks(_ block: RichBlock) -> [RichBlock] {
        guard case .paragraph(let text) = block, text.text.utf16.contains(10) else { return [block] }
        var result: [RichBlock] = []
        var lineStart = 0
        for (offset, unit) in text.text.utf16.enumerated() where unit == 10 {
            result.append(.paragraph(text.slice(lineStart..<offset)))
            lineStart = offset + 1
        }
        result.append(.paragraph(text.slice(lineStart..<text.length)))
        return result
    }

    /// A parse drops spaces and tabs at the edges of a paragraph. The plain text of a partial copy still has them.
    private static func restoringEdgeSpaces(_ blocks: [RichBlock], plainText: String?) -> [RichBlock] {
        guard blocks.count == 1, case .paragraph(let text) = blocks[0], let plainText else { return blocks }
        let units = Array(plainText.utf16)
        var lower = 0
        var upper = units.count
        while lower < upper, isSpaceOrTab(units[lower]) { lower += 1 }
        while upper > lower, isSpaceOrTab(units[upper - 1]) { upper -= 1 }
        guard lower > 0 || upper < units.count, String(decoding: units[lower..<upper], as: UTF16.self) == visibleText(text) else { return blocks }
        let leading = RichText(String(decoding: units[..<lower], as: UTF16.self))
        let trailing = RichText(String(decoding: units[upper...], as: UTF16.self))
        return [.paragraph(leading + text + trailing)]
    }

    private static func isSpaceOrTab(_ unit: UInt16) -> Bool {
        unit == 32 || unit == 9
    }

    private static func visibleText(_ text: RichText) -> String {
        text.text.replacingOccurrences(of: "\u{2028}", with: "\n")
    }

    private static func plainText(of blocks: [RichBlock]) -> String {
        let numbers = RichDocument.orderedNumbers(of: blocks)
        var lines: [String] = []
        for (index, block) in blocks.enumerated() {
            switch block {
            case .listItem(let item, let text):
                let marker = switch item.isChecked {
                case true?: "- [x] "
                case false?: "- [ ] "
                case nil: item.isOrdered ? "\(numbers[index] ?? 1). " : "- "
                }
                lines.append(String(repeating: "  ", count: item.indent) + marker + visibleText(text))
            case .paragraph(let text), .heading(_, let text), .quote(_, let text):
                lines.append(visibleText(text))
            case .codeBlock(_, let code):
                lines.append(code)
            case .thematicBreak:
                lines.append("")
            case .rawSource(let source):
                lines.append(source)
            }
        }
        return lines.joined(separator: "\n")
    }
}
