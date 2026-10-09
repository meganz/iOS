import UIKit

/// Selection over rows. Another component owns it. The editor forwards the keys it cannot handle in one row.
@MainActor
protocol RichSelectionHandler: AnyObject {
    /// ⇧ with an arrow at the edge of row `row`: the selection grows past it.
    func extendSelection(fromRow row: Int, through edge: RichTextView.Edge)
    /// Typed text while a selection over rows is active. Returns false to let the model insert it.
    func insertText(_ text: String) -> Bool
    /// Backspace while a selection over rows is active. Returns false to let the model delete.
    func deleteBackward() -> Bool
    /// Called once after every model action, after the list shows it. Undo, redo and Select All move the selection too.
    func modelDidChange()
    /// Select All from a row, the selection responder or ⌘A. The handler selects the document and can show its menu.
    func selectAll()
    /// The end of the model's selection that the user moves, when the handler knows it. The list scrolls to it.
    var selectionHead: RichPosition? { get }
}

/// Takes the keyboard when the selection has no text view: a divider or raw block, or a selection over rows.
/// One per list. Keys go to the model, or to the selection handler while a selection over rows is active.
final class RichSelectionResponder: UIView, UIKeyInput {
    weak var model: RichEditorModel?
    weak var selectionHandler: (any RichSelectionHandler)?
    var modelUndoManager: ModelUndoManager?
    /// An arrow up or down: the caret goes to the row before or after the selection.
    var onLeave: ((RichTextView.Edge) -> Void)?
    /// ⇧ with an arrow up or down.
    var onShiftArrow: ((RichTextView.Edge) -> Void)?
    var onResign: (() -> Void)?
    /// Tests use a named pasteboard: reading the general one without a user action waits for permission.
    var pasteboard = UIPasteboard.general

    override var canBecomeFirstResponder: Bool { true }
    var hasText: Bool { true }
    var autocorrectionType: UITextAutocorrectionType = .no

    override var undoManager: UndoManager? {
        modelUndoManager
    }

    private var isOverRows: Bool {
        model.map { !$0.selection.isInOneBlock } ?? false
    }

    func insertText(_ text: String) {
        if isOverRows, selectionHandler?.insertText(text) == true { return }
        guard let model else { return }
        if text == "\n" {
            model.insertParagraphBreak()
        } else {
            model.insertText(text)
        }
    }

    func deleteBackward() {
        if isOverRows, selectionHandler?.deleteBackward() == true { return }
        model?.deleteBackward()
    }

    // MARK: - Edit actions

    // The edit menu for a selection over rows and the hardware ⌘C, ⌘X, ⌘V and ⌘A call these.

    override func copy(_ sender: Any?) {
        guard let content = model?.copy() else { return }
        RichPasteboard.write(content, to: pasteboard)
    }

    override func cut(_ sender: Any?) {
        guard let content = model?.cut() else { return }
        RichPasteboard.write(content, to: pasteboard)
    }

    override func paste(_ sender: Any?) {
        guard let content = RichPasteboard.read(from: pasteboard) else { return }
        model?.paste(content)
    }

    override func delete(_ sender: Any?) {
        model?.deleteSelection()
    }

    override func selectAll(_ sender: Any?) {
        if let selectionHandler {
            selectionHandler.selectAll()
        } else {
            model?.selectAll()
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        let hasRange = model.map { !$0.selection.isCaret } ?? false
        switch action {
        case #selector(copy(_:)), #selector(cut(_:)), #selector(delete(_:)): return hasRange
        case #selector(paste(_:)): return RichPasteboard.canPaste(from: pasteboard)
        case #selector(selectAll(_:)): return model != nil
        default: return super.canPerformAction(action, withSender: sender)
        }
    }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned { onResign?() }
        return resigned
    }

    override var keyCommands: [UIKeyCommand]? {
        let arrows = [
            Self.command(UIKeyCommand.inputUpArrow, [], #selector(upPressed)),
            Self.command(UIKeyCommand.inputDownArrow, [], #selector(downPressed))
        ]
        // Only the selection handler can grow a selection over rows.
        guard selectionHandler != nil else { return arrows }
        return arrows + [
            Self.command(UIKeyCommand.inputUpArrow, .shift, #selector(shiftUpPressed)),
            Self.command(UIKeyCommand.inputDownArrow, .shift, #selector(shiftDownPressed))
        ]
    }

    private static func command(_ input: String, _ flags: UIKeyModifierFlags, _ action: Selector) -> UIKeyCommand {
        let command = UIKeyCommand(input: input, modifierFlags: flags, action: action)
        command.wantsPriorityOverSystemBehavior = true
        return command
    }

    @objc private func upPressed() { onLeave?(.up) }
    @objc private func downPressed() { onLeave?(.down) }
    @objc private func shiftUpPressed() { onShiftArrow?(.up) }
    @objc private func shiftDownPressed() { onShiftArrow?(.down) }
}
