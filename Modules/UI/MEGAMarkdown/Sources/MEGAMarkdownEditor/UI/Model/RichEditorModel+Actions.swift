import Foundation

// One method per user action. Each runs one `RichEditor` method through `mutate`.
extension RichEditorModel {
    // MARK: - Selection

    /// A caret move or a new selection made by the user. Not for the caret move that typing makes.
    func select(_ selection: RichSelection) {
        mutate { $0.select(selection) }
    }

    func selectAll() {
        mutate { $0.selectAll() }
    }

    /// A tap below the last row.
    func placeCaretAtEnd() {
        mutate { $0.placeCaretAtEnd() }
    }

    // MARK: - Typing

    /// The text view of `row` replaces `range` with `string`. Keeps the typing styles.
    func replaceText(inRow row: Int, range: Range<Int>, with string: String) {
        mutate(cause: .typing(row: row)) { $0.replaceText(inBlock: row, range: range, with: string) }
    }

    /// The text view of `row` changed without telling the range (dictation, some keyboards).
    func didChangeText(inRow row: Int, to text: String, caret: Int?) {
        mutate(cause: .typing(row: row)) { $0.didChangeText(inBlock: row, to: text, caret: caret) }
    }

    /// Text typed while the selection has no text view (a divider, a raw block, or a selection across rows).
    func insertText(_ string: String) {
        mutate { $0.insertText(string) }
    }

    /// Enter.
    func insertParagraphBreak() {
        mutate { $0.insertParagraphBreak() }
    }

    /// Backspace.
    func deleteBackward() {
        mutate { $0.deleteBackward() }
    }

    func deleteSelection() {
        mutate { $0.deleteSelection() }
    }

    // MARK: - Formatting

    func toggleStyle(_ style: RichSpanStyle) {
        mutate { $0.toggleStyle(style) }
    }

    /// Heading, list, quote, indent and outdent.
    func apply(_ action: RichBlockAction) {
        mutate { $0.apply(action) }
    }

    func toggleCheckbox(inRow row: Int) {
        mutate(cause: .checkbox) { $0.toggleCheckbox(at: row) }
    }

    // MARK: - Links

    /// Opens the link dialog on the selection. Does nothing for a selection across rows or outside text.
    func beginLinkEditing() {
        guard let target = editor.linkTarget() else { return }
        setLinkDialog(RichLinkDialog(target: target, draft: editor.linkDraft(for: target)))
    }

    /// Returns false when the URL is not valid. The dialog then stays open.
    @discardableResult
    func saveLink(urlText: String, label: String) -> Bool {
        guard let dialog = linkDialog else { return false }
        var saved = false
        mutate { saved = $0.saveLink(dialog.target, urlText: urlText, label: label) }
        if saved { setLinkDialog(nil) }
        return saved
    }

    /// False when Save would fail for this URL. The dialog turns its Save button off.
    func canSaveLink(urlText: String) -> Bool {
        guard let dialog = linkDialog else { return false }
        return editor.canSaveLink(dialog.target, urlText: urlText)
    }

    func removeLink() {
        guard let dialog = linkDialog else { return }
        mutate { $0.removeLink(dialog.target) }
        setLinkDialog(nil)
    }

    func cancelLinkEditing() {
        setLinkDialog(nil)
    }

    // MARK: - Clipboard

    func copy() -> RichClipboardContent? {
        editor.copy()
    }

    func cut() -> RichClipboardContent? {
        var content: RichClipboardContent?
        mutate { content = $0.cut() }
        return content
    }

    func paste(_ content: RichPasteContent) {
        mutate { $0.paste(content) }
    }

    // MARK: - Undo

    func undo() {
        mutate { $0.undo() }
    }

    func redo() {
        mutate { $0.redo() }
    }
}
