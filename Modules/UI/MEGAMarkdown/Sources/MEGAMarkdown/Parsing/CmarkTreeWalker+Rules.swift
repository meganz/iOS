import cmark_gfm
import cmark_gfm_extensions

// MARK: - Rules shared with Foundation

/// Pure functions. Each one keeps a rule of Foundation's `AttributedString(markdown:)` so the output stays the same.
extension CmarkTreeWalker {
    /// Matched style tags (`<u>`, `<strong>`, ...) are removed and style the text between them.
    /// Unmatched tags stay as literal text. Same rules as Foundation.
    static func applyStyleTags(_ pieces: [Piece], links: [InlineLink]) -> InlineText {
        // cmark makes one node per tag. `InlineText.append` joins equal neighbour runs, so no merge is needed here.
        let merged = pieces
        var tags: [StyleTag] = []
        for (index, piece) in merged.enumerated() where piece.style.contains(.inlineHTML) {
            tags += StyleTag.tags(in: piece.text, run: index, link: piece.link)
        }
        StyleTag.markMatchedPairs(&tags)
        var result = InlineText(links: links)
        // Exact capacity: appending grows storage up to 2x, and big files keep millions of these.
        let hasStyle = merged.contains { !$0.style.isEmpty || $0.link >= 0 }
        result.reserveCapacity(bytes: merged.reduce(0) { $0 + $1.text.utf8.count }, runs: hasStyle ? merged.count : 0)
        guard tags.contains(where: \.isMatched) else {
            for piece in merged { result.append(piece.text, style: piece.style, link: piece.link) }
            return result
        }
        var depth: [StyleTag.Style: Int] = [:]
        var tagIndex = 0
        for (index, piece) in merged.enumerated() {
            guard tagIndex < tags.count, tags[tagIndex].run == index else {
                result.append(piece.text, style: styled(piece.style, depth: depth), link: piece.link)
                continue
            }
            while tagIndex < tags.count, tags[tagIndex].run == index {
                let tag = tags[tagIndex]
                tagIndex += 1
                if tag.isMatched {
                    depth[tag.style, default: 0] += tag.isClosing ? -1 : 1
                } else {
                    result.append(tag.text, style: styled(piece.style, depth: depth), link: piece.link)
                }
            }
        }
        return result
    }

    private static func styled(_ style: InlineStyle, depth: [StyleTag.Style: Int]) -> InlineStyle {
        var result = style
        for (tagStyle, count) in depth where count > 0 {
            switch tagStyle {
            case .bold: result.insert(.stronglyEmphasized)
            case .italic: result.insert(.emphasized)
            case .strikethrough: result.insert(.strikethrough)
            case .code: result.insert(.code)
            case .underline: result.insert(.underline)
            }
        }
        return result
    }

    /// A paragraph of exactly one image with a URL becomes an image block (same rule as Foundation).
    /// Two images stay a paragraph, so neither URL is lost.
    static func imageBlockKind(for text: InlineText) -> ParsedBlock.Kind? {
        let runs = text.runs
        guard !runs.isEmpty, runs.allSatisfy({ $0.style.contains(.image) }) else { return nil }
        let linkIndexes = Set(runs.map(\.link))
        guard linkIndexes.count == 1, let link = linkIndexes.first, !text.links[link].url.isEmpty else { return nil }
        // The parser's own placeholder keeps the block alive. It is not alt text, so it must not reach the model.
        var altText = ""
        var start = 0
        for run in runs {
            if !run.style.contains(.placeholder) {
                let utf8 = text.text.utf8
                altText += String(text.text[utf8.index(utf8.startIndex, offsetBy: start)..<utf8.index(utf8.startIndex, offsetBy: run.end)])
            }
            start = run.end
        }
        return .image(url: text.links[link].url, altText: altText)
    }

    static func columns(_ node: UnsafeMutablePointer<cmark_node>, count: Int) -> [MarkdownTable.Column] {
        let alignments = cmark_gfm_extensions_get_table_alignments(node)
        return (0..<count).map { index in
            switch alignments?[index] {
            case UInt8(ascii: "l"): MarkdownTable.Column(alignment: .left)
            case UInt8(ascii: "c"): MarkdownTable.Column(alignment: .center)
            case UInt8(ascii: "r"): MarkdownTable.Column(alignment: .right)
            // Foundation has no "none" alignment and gives left. Both draw the same.
            default: MarkdownTable.Column(alignment: .left)
            }
        }
    }
}
