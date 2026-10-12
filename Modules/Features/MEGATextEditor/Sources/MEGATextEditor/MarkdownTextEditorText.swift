import Foundation

/// Turns file bytes into Markdown text. The Markdown views need valid UTF-8.
public enum MarkdownTextEditorText {
    /// Returns nil when the bytes are not valid UTF-8.
    public static func decode(_ data: Data) -> String? {
        String(data: data, encoding: .utf8)
    }
}
