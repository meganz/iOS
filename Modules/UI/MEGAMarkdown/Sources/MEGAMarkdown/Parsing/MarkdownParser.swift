import Foundation
import MEGAFoundation

/// Turns Markdown text into a `MarkdownDocument` with cmark-gfm (CommonMark + GFM tables, strikethrough, autolinks).
/// Safe to call off the main thread, also from several threads at once.
public enum MarkdownParser {
    public static func parse(
        _ markdown: String,
        baseURL: URL? = nil,
        softBreak: MarkdownSoftBreak = .lineBreak
    ) -> MarkdownDocument {
        guard let blocks = CmarkParser.blocks(markdown, softBreak: softBreak) else {
            // cmark failed: show the raw text so the user still sees the content.
            MEGALog.log(level: .warning, message: "[MarkdownParser] cmark could not parse, showing raw text. bytes=\(markdown.utf8.count)")
            return MarkdownDocument(blocks: [MarkdownBlock(id: 0, sourceLine: 0, kind: .paragraph(AttributedString(markdown)))])
        }
        var nextID = 0
        return MarkdownDocument(blocks: blocks.map { $0.markdownBlock(nextID: &nextID, baseURL: baseURL) })
    }
}
