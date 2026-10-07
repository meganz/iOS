import MEGAMarkdown

/// One parsed top-level block -> rich rows. nil when the rich model cannot hold the block.
/// The importer then keeps the block's source lines as `.rawSource`.
enum RichBlockConversion {
    /// Quotes and lists deeper than this stay raw. The parser stops nesting at 64 and joins deeper content.
    static let maxDepth = 60

    static func rows(for block: ParsedBlock) -> [RichBlock]? {
        switch block.kind {
        case .heading(let level, let text):
            return richText(from: text).map { [.heading(level: level, text: $0)] }
        case .paragraph(let text):
            return richText(from: text).map { [.paragraph($0)] }
        case .codeBlock(let language, let code):
            return [.codeBlock(language: language, code: code)]
        case .thematicBreak:
            return [.thematicBreak]
        case .blockQuote(let children):
            // An empty quote has no row to show it, and an empty quote row is not saved.
            guard !children.isEmpty else { return nil }
            return quoteRows(children, depth: 1)
        case .list(let list):
            return listRows(list, indent: 0)
        case .table, .image:
            return nil
        }
    }

    // MARK: - Containers

    private static func quoteRows(_ children: [ParsedBlock], depth: Int) -> [RichBlock]? {
        guard depth <= maxDepth else { return nil }
        var rows: [RichBlock] = []
        for child in children {
            switch child.kind {
            case .paragraph(let text):
                guard let rich = richText(from: text), !rich.isEmpty else { return nil }
                rows.append(.quote(depth: depth, text: rich))
            case .blockQuote(let nested):
                guard !nested.isEmpty, let nestedRows = quoteRows(nested, depth: depth + 1) else { return nil }
                rows += nestedRows
            default:
                return nil
            }
        }
        return rows
    }

    /// Flattens a list. An item must be empty, one paragraph, or one paragraph or nothing followed by lists.
    private static func listRows(_ list: ParsedList, indent: Int) -> [RichBlock]? {
        guard indent <= maxDepth else { return nil }
        var rows: [RichBlock] = []
        for (index, item) in list.items.enumerated() {
            var text = RichText()
            var rest = item.blocks[...]
            if let first = rest.first, case .paragraph(let inline) = first.kind {
                guard let rich = richText(from: inline) else { return nil }
                text = rich
                rest = rest.dropFirst()
            }
            let startNumber = (list.isOrdered && index == 0 && list.startIndex != 1) ? list.startIndex : nil
            let checked: Bool? = switch item.checkbox {
            case .checked: true
            case .unchecked: false
            case nil: nil
            }
            rows.append(.listItem(RichListItem(isOrdered: list.isOrdered, indent: indent, isChecked: checked, startNumber: startNumber), text: text))
            for child in rest {
                guard case .list(let nested) = child.kind, let nestedRows = listRows(nested, indent: indent + 1) else { return nil }
                rows += nestedRows
            }
        }
        return rows
    }

    // MARK: - Inline

    /// Parser text -> rich text. nil when it holds what the model cannot: images, raw HTML,
    /// or the parser's placeholder for an empty link text.
    /// A soft break stays "\n". A hard break becomes U+2028, so the two stay apart.
    static func richText(from inline: InlineText) -> RichText? {
        let refused: InlineStyle = [.image, .placeholder, .inlineHTML, .blockHTML]
        let source = inline.text.utf8
        var text = ""
        text.reserveCapacity(source.count)
        var spans: [RichSpan] = []
        var start = source.startIndex
        var offset = 0
        for run in inline.runs {
            guard run.style.isDisjoint(with: refused) else { return nil }
            let end = source.index(source.startIndex, offsetBy: run.end)
            // Runs end on scalar boundaries, not always on Character boundaries, so the bytes are copied.
            let piece = run.style.contains(.lineBreak) ? "\u{2028}" : String(decoding: source[start..<end], as: UTF8.self)
            start = end
            // A line end that is not a break (from `&#10;`) would write back as a soft break.
            if !run.style.contains(.softBreak) && !run.style.contains(.lineBreak), piece.unicodeScalars.contains(where: { $0 == "\n" || $0 == "\u{2028}" }) {
                return nil
            }
            let length = piece.utf16.count
            let range = offset..<(offset + length)
            text += piece
            offset += length
            if run.style.contains(.stronglyEmphasized) { spans.append(RichSpan(range: range, style: .bold)) }
            if run.style.contains(.emphasized) { spans.append(RichSpan(range: range, style: .italic)) }
            if run.style.contains(.strikethrough) { spans.append(RichSpan(range: range, style: .strikethrough)) }
            if run.style.contains(.code) { spans.append(RichSpan(range: range, style: .code)) }
            if run.style.contains(.underline) { spans.append(RichSpan(range: range, style: .underline)) }
            if run.link >= 0, run.link < inline.links.count {
                let link = inline.links[run.link]
                spans.append(RichSpan(range: range, style: .link(RichLink(destination: link.url, title: link.title))))
            }
        }
        return RichText(text, spans: spans)
    }
}
