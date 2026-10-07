import Foundation

extension RichEditor {
    /// The clipboard content of the selection. nil for a caret.
    func copy() -> RichClipboardContent? {
        RichClipboard.content(of: document, in: selection)
    }

    /// Copy, then delete the selection. One undo step.
    mutating func cut() -> RichClipboardContent? {
        guard let content = copy() else { return nil }
        deleteSelection()
        return content
    }

    /// Replaces the selection with pasted content. One undo step.
    /// In a text block the Markdown is parsed, so syntax renders. In a code block the text goes in as code.
    /// Typing styles do not apply: pasted text keeps its own styles.
    mutating func paste(_ content: RichPasteContent) {
        var (document, caret) = document.deleting(selection)
        if case .codeBlock = document.blocks[caret.blockIndex] {
            (document, caret) = document.insertingCode(RichClipboard.codeText(from: content), at: caret)
        } else {
            let blocks = RichClipboard.blocks(from: content)
            guard !blocks.isEmpty || !selection.isCaret else { return }
            (document, caret) = document.inserting(blocks, at: caret)
        }
        commit(document.blocks, caret: caret)
    }
}
