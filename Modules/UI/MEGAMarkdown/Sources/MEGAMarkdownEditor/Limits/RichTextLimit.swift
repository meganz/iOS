import Foundation

/// The largest text rich mode opens. Larger texts open in source mode.
enum RichTextLimit {
    /// In UTF-16 units. The Android editor uses 50,000. `RichEditorBenchmarks` measures open, typing and Enter at this size.
    static let maxLength = 500_000

    /// O(1) for most texts, so the editor can call it on the main thread.
    static func allowsRichMode(_ markdown: String) -> Bool {
        !markdown.hasUTF16Count(over: maxLength)
    }
}
