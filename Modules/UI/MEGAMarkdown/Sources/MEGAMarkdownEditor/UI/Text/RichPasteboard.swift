import UIKit
import UniformTypeIdentifiers

/// Writes and reads the editor's clipboard content on a `UIPasteboard`.
/// A copy is one pasteboard item with two types: other apps read the plain text, the editors read the Markdown.
/// A part of a code block adds the empty `RichClipboardContent.codePartType`.
@MainActor
enum RichPasteboard {
    static func write(_ content: RichClipboardContent, to pasteboard: UIPasteboard) {
        var item: [String: Any] = [
            UTType.utf8PlainText.identifier: content.plainText,
            RichClipboardContent.markdownType: content.markdown
        ]
        if content.isCodePart { item[RichClipboardContent.codePartType] = Data() }
        pasteboard.setItems([item])
    }

    /// Both types when the copy has both, so the model can use plain text for a code block. nil when there is neither.
    static func read(from pasteboard: UIPasteboard) -> RichPasteContent? {
        var content = RichPasteContent()
        if let data = pasteboard.data(forPasteboardType: RichClipboardContent.markdownType) {
            content.markdown = String(data: data, encoding: .utf8)
        }
        content.plainText = pasteboard.string
        return content.markdown == nil && content.plainText == nil ? nil : content
    }

    /// True when a paste would read something. Does not read the content, so it asks for no paste permission.
    static func canPaste(from pasteboard: UIPasteboard) -> Bool {
        pasteboard.contains(pasteboardTypes: [RichClipboardContent.markdownType]) || pasteboard.hasStrings
    }
}
