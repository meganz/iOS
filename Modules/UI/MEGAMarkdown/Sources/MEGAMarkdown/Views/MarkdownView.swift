import SwiftUI

/// Shows short Markdown inside other content. It parses on the main thread and builds every block.
/// Keep the text under 4 KB. `RendererBenchmarks` measures that size.
/// On a simulator, 4 KB already blocks the main thread for about 100 ms.
/// `package`: other targets of this package use it. It is not public API.
package struct MarkdownView: View {
    private enum Content {
        case markdown(MarkdownParseRequest)
        case document(MarkdownDocument)
    }

    private let content: Content

    /// Keeps the last parse, so a parent redraw with the same text does not parse again.
    @State private var cache = MarkdownParseCache()
    @Environment(\.markdownTheme) private var theme

    /// Parses on the main thread when the text changes, so the first frame already shows the content.
    /// - Parameters:
    ///   - markdown: The Markdown text to show.
    ///   - baseURL: Resolves relative links and image paths. Nil keeps them relative.
    ///   - softBreak: How a single newline inside a paragraph is shown. Default: a line break, like Android.
    package init(_ markdown: String, baseURL: URL? = nil, softBreak: MarkdownSoftBreak = .lineBreak) {
        content = .markdown(MarkdownParseRequest(markdown: markdown, baseURL: baseURL, softBreak: softBreak))
    }

    /// Shows a document that is already parsed, for example with `MarkdownParser.parse` off the main thread.
    package init(document: MarkdownDocument) {
        content = .document(document)
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: theme.blockSpacing) {
            ForEach(document.blocks) { block in
                MarkdownBlockView(block: block)
            }
        }
        // No `.textSelection`: SwiftUI then skips `InlineCodeChipRenderer`, and inline code loses its border.
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var document: MarkdownDocument {
        switch content {
        case .markdown(let request):
            cache.document(for: request)
        case .document(let document):
            document
        }
    }
}

// MARK: - Parse cache

/// Parses only when the request changes. A class, so the view can update it while it draws.
@MainActor
final class MarkdownParseCache {
    private var last: ParsedMarkdown?
    private let parse: (MarkdownParseRequest) -> MarkdownDocument

    /// Only tests pass `parse`, to count the real parses.
    init(parse: @escaping (MarkdownParseRequest) -> MarkdownDocument = { $0.parse() }) {
        self.parse = parse
    }

    func document(for request: MarkdownParseRequest) -> MarkdownDocument {
        if let last, last.source == request {
            return last.document
        }
        let document = parse(request)
        last = ParsedMarkdown(source: request, document: document)
        return document
    }
}
