import cmark_gfm
import cmark_gfm_extensions
import Foundation

/// How much the walker keeps.
package enum ParseMode: Sendable {
    /// Same output as Foundation's `AttributedString(markdown:)`: empty blocks are dropped (rules R1 and R2 in DECISIONS.md).
    case viewer
    /// For an editor that writes Markdown back: empty blocks stay, a code block keeps its trailing blank lines,
    /// and alt text of an image inside a link keeps the image bit.
    case editor
}

/// The only code that talks to the cmark-gfm C API, with `CmarkParser+ChunkProbe.swift` and `CmarkTreeWalker.swift`.
/// The tree is walked with `cmark_iter` (no recursion), so deep nesting cannot overflow the stack.
package enum CmarkParser {
    /// Quotes and list items deeper than this are not opened. Their content joins the deepest open one.
    static let maxNestingDepth = 64

    /// Returns nil only when cmark cannot create a parser.
    static func blocks(_ markdown: String, softBreak: MarkdownSoftBreak) -> [ParsedBlock]? {
        var source = markdown
        return source.withUTF8 { buffer in
            blocks(prefix: [], body: buffer, softBreak: softBreak, lineOffset: 0, lastLine: 0)?.blocks
        }
    }

    /// Parses `prefix` + `body` as one text. Block lines are shifted by `lineOffset` (0-based result).
    /// `lastLine` is the line of the block before this text, used when cmark gives no line.
    static func blocks(
        prefix: [UInt8],
        body: UnsafeBufferPointer<UInt8>,
        softBreak: MarkdownSoftBreak,
        lineOffset: Int,
        lastLine: Int
    ) -> (blocks: [ParsedBlock], lastLine: Int)? {
        prefix.withUnsafeBufferPointer { prefixBytes in
            withTree(prefix: prefix, body: body) { root in
                let source = CmarkTreeWalker.SourceText(prefix: prefixBytes, body: body)
                var walker = CmarkTreeWalker(source: source, softBreak: softBreak, lineOffset: lineOffset, lastLine: lastLine)
                let blocks = walker.walk(root)
                return (blocks, walker.lastBlockLine)
            }
        }
    }

    /// Editor mode: nothing is dropped, and each top-level block comes with its source lines.
    /// `lines[i]` holds the 0-based first and last line of `blocks[i]`. Returns nil only when cmark cannot create a parser.
    package static func editorBlocks(_ markdown: String) -> (blocks: [ParsedBlock], lines: [ClosedRange<Int>])? {
        var source = markdown
        return source.withUTF8 { body in
            withTree(prefix: [], body: body) { root in
                [UInt8]().withUnsafeBufferPointer { prefix in
                    let text = CmarkTreeWalker.SourceText(prefix: prefix, body: body)
                    var walker = CmarkTreeWalker(source: text, softBreak: .lineBreak, mode: .editor)
                    let blocks = walker.walk(root)
                    return (blocks, walker.topLevelLines)
                }
            }
        }
    }

    // MARK: - Helpers

    /// Makes a parser, feeds the two parts, and frees the parser and the tree after `work`.
    static func withTree<Result>(
        prefix: [UInt8],
        body: UnsafeBufferPointer<UInt8>,
        _ work: (UnsafeMutablePointer<cmark_node>) -> Result
    ) -> Result? {
        cmark_gfm_core_extensions_ensure_registered()
        guard let parser = cmark_parser_new(CMARK_OPT_SOURCEPOS) else { return nil }
        defer { cmark_parser_free(parser) }
        // `tasklist` marks task items from the source line, like GitHub does. An escaped `\[x]` stays text.
        for name in ["table", "strikethrough", "autolink", "tasklist"] {
            guard let syntaxExtension = cmark_find_syntax_extension(name) else { continue }
            cmark_parser_attach_syntax_extension(parser, syntaxExtension)
        }
        prefix.withUnsafeBufferPointer { feed(parser, $0) }
        feed(parser, body)
        guard let root = cmark_parser_finish(parser) else { return nil }
        defer { cmark_node_free(root) }
        return work(root)
    }

    private static func feed(_ parser: UnsafeMutablePointer<cmark_parser>, _ bytes: UnsafeBufferPointer<UInt8>) {
        bytes.withMemoryRebound(to: CChar.self) { chars in
            if let base = chars.baseAddress, chars.count > 0 {
                cmark_parser_feed(parser, base, chars.count)
            }
        }
    }

    static func string(_ pointer: UnsafePointer<CChar>?) -> String {
        pointer.map { String(cString: $0) } ?? ""
    }
}
