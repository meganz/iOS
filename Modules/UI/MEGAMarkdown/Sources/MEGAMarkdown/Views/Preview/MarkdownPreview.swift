import MEGADesignToken
import SwiftUI

/// Where the user is in a `MarkdownPreview`.
public struct MarkdownReadingPosition: Equatable, Sendable {
    /// The source line of the top row.
    public let topLine: Int
    /// From 0 to 1: the source line of the first row below the screen divided by the line count,
    /// or 1 once the last row of the complete text is on screen.
    public let progress: Double

    public init(topLine: Int, progress: Double) {
        self.topLine = topLine
        self.progress = progress
    }
}

/// Full-screen, read-only Markdown reader for big text. It parses off the main thread in chunks of about 1 MB
/// and shows the first rows before the rest is parsed. Only the rows on screen are built.
/// It reports the reading position while the user scrolls, and can open at a saved line.
/// Text over `sizeLimitInBytes` shows a "too large" message.
public struct MarkdownPreview: View {
    /// Bigger text (UTF-8 bytes) is not shown. Check a file's size against this before reading it into a String.
    public nonisolated static let sizeLimitInBytes = 100 * 1024 * 1024

    private let request: MarkdownParseRequest
    private let restoreLine: Int?
    private let onReadingPositionChange: ((MarkdownReadingPosition) -> Void)?
    /// Tests set it to hold the parse.
    var parseLimits = PreviewParseLimits()

    @State private var model = PreviewModel()
    @Environment(\.markdownTheme) private var theme
    @Environment(\.markdownPreviewStrings) private var strings

    /// - Parameters:
    ///   - markdown: The Markdown text to show.
    ///   - baseURL: Resolves relative links and image paths. Nil keeps them relative.
    ///   - softBreak: How a single newline inside a paragraph is shown. Default: a line break, like Android.
    ///   - restoreLine: 0-based source line to open at. The reader shows the row that contains it at the top.
    ///   - onReadingPositionChange: Called when the top line or the read progress changes. It is not called
    ///     while a restore waits for its row, and not after the view is gone.
    public init(
        _ markdown: String,
        baseURL: URL? = nil,
        softBreak: MarkdownSoftBreak = .lineBreak,
        restoreLine: Int? = nil,
        onReadingPositionChange: ((MarkdownReadingPosition) -> Void)? = nil
    ) {
        request = MarkdownParseRequest(markdown: markdown, baseURL: baseURL, softBreak: softBreak)
        self.restoreLine = restoreLine
        self.onReadingPositionChange = onReadingPositionChange
    }

    public var body: some View {
        content
            // A new text cancels the old load. The old rows stay until the new text sends its first rows,
            // so the spinner shows only on the first load. The id compares the text by bytes.
            .task(id: request) {
                await model.load(request, limits: parseLimits)
            }
    }

    @ViewBuilder private var content: some View {
        switch model.phase {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .tooLarge:
            Text(strings.tooLarge)
                .font(theme.bodyFont)
                .foregroundStyle(theme.bodyColor)
                .multilineTextAlignment(.center)
                .padding(TokenSpacing._5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("markdown.preview.tooLarge")
        case .rows:
            // The reader reads the safe area here, before the list ignores it. UIKit does not see host bars
            // added with `safeAreaInset`, so the list gets the SwiftUI safe area as its insets.
            GeometryReader { proxy in
                PreviewRowList(
                    store: model.store,
                    generation: model.generation,
                    rowCount: model.rowCount,
                    isComplete: model.isComplete,
                    lineCount: model.lineCount,
                    showsCurrentText: model.shownRequest == request,
                    baseURL: model.baseURL,
                    restoreLine: restoreLine,
                    onReadingPositionChange: onReadingPositionChange,
                    safeArea: proxy.safeAreaInsets
                )
                // Rows scroll under the bars. The list insets keep the first and last rows clear of them.
                .ignoresSafeArea(edges: .vertical)
            }
        }
    }
}

#Preview {
    MarkdownPreview("""
    # Title
    Some **bold**, *italic*, `code` and a [link](https://mega.io).

    - [x] Done
    - [ ] Todo

    > Quote

    | A | B |
    |:--|--:|
    | 1 | 2 |
    """)
}
