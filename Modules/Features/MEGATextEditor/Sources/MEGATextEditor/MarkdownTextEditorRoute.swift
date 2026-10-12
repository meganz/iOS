import MEGASwift

/// Where a text file opens. A host asks before it reads or downloads the file.
public enum MarkdownTextEditorRoute: Equatable, Sendable {
    /// Not a Markdown file, or the Markdown screen is turned off.
    case otherFile
    /// A Markdown file that the Markdown screen can show.
    case markdownFile
    /// A Markdown file over `MarkdownPreview.sizeLimitInBytes`.
    case tooLarge

    /// - Parameters:
    ///   - sizeInBytes: The size of the file. A new file has size 0.
    ///   - isEnabled: Whether the host turned the Markdown screen on.
    public init(fileName: String, sizeInBytes: UInt64, isEnabled: Bool) {
        guard isEnabled, fileName.fileExtensionGroup.isMarkdownText else {
            self = .otherFile
            return
        }
        switch MarkdownTextEditorSizeCheck(sizeInBytes: sizeInBytes) {
        case .previewable: self = .markdownFile
        case .tooLarge: self = .tooLarge
        }
    }
}
