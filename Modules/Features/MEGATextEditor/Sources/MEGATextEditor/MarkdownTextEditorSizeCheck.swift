import MEGAMarkdown

/// Decides if a Markdown file can open, from its size alone. No byte of the file is read.
public enum MarkdownTextEditorSizeCheck: Equatable, Sendable {
    /// The file is small enough for the preview.
    case previewable
    /// The file is over `MarkdownPreview.sizeLimitInBytes`.
    case tooLarge

    public init(sizeInBytes: UInt64) {
        self = sizeInBytes > UInt64(MarkdownPreview.sizeLimitInBytes) ? .tooLarge : .previewable
    }
}
