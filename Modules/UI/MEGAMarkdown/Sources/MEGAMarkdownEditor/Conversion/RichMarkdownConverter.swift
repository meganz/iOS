import Foundation

/// Converts between Markdown text and `RichDocument`.
enum RichMarkdownConverter {
    /// Markdown -> document. A block the model cannot hold becomes `.rawSource` with its exact source lines.
    /// The result also holds the export of the document, which is the baseline of the dirty check.
    static func load(_ markdown: String) -> RichImport {
        MarkdownImporter.load(markdown)
    }

    static func document(from markdown: String) -> RichDocument {
        MarkdownImporter.load(markdown).document
    }

    /// Document -> Markdown file text, with the file's line ending, byte order mark and last line end.
    static func markdown(from document: RichDocument) -> String {
        var cache = InlineExportCache()
        return markdown(from: document, cache: &cache)
    }

    /// Same, reusing the inline pieces of the last export. `cache` gets the pieces of this export.
    static func markdown(from document: RichDocument, cache: inout InlineExportCache) -> String {
        var exporter = MarkdownExporter(blocks: document.blocks, previous: cache)
        let body = exporter.markdown()
        cache = exporter.current
        return MarkdownSourceText.file(body: body, format: document.format)
    }

    /// Blocks -> Markdown with "\n" line ends and no line end at the end. For the clipboard.
    static func markdownFragment(from blocks: [RichBlock]) -> String {
        var exporter = MarkdownExporter(blocks: blocks)
        return exporter.markdown()
    }
}
