import MEGAFoundation
import MEGAMarkdown
import UIKit

// The focus path: the only place that moves the keyboard focus between rows.
extension RichRowAdapter {
    /// Gives the keyboard to the model's selection. A caret or a range in one text row: that row's text view.
    /// Anything else (an atomic row, a selection over rows): the selection responder.
    /// Far rows are pinned and scrolled to first, so their cell exists when it takes the focus.
    func focusSelection() {
        let selection = model.selection
        let row = selection.end.blockIndex
        guard selection.isInOneBlock, row < model.rowCount, model.row(at: row).block.plainText != nil else {
            focusOutsideRows()
            return
        }
        let item = items(forRow: row).lowerBound
        let range = NSRange(location: selection.start.offset, length: selection.end.offset - selection.start.offset)
        list.pinnedItem = item
        if let textView = textView(forItem: item), textView.isFirstResponder {
            // Undo and paste in the focused row: only the caret moves.
            textView.setSelectionFromModel(range)
            textView.onTypingStylesChange?()
            scrollCaretToVisible(in: textView)
            return
        }
        // Only the row's top edge, so its cell exists. The caret scroll below shows the rest; the whole row would
        // also bring in its gap below and move a row that is already on screen.
        list.scrollToItem(item, rect: CGRect(x: 0, y: 0, width: 1, height: 1)) {
            guard let textView = textView(forItem: item) else {
                MEGALog.log(level: .warning, message: "[RichRowAdapter] No text view to focus after the scroll. row=\(row)")
                return
            }
            textView.focusFromModel(selection: range)
            scrollCaretToVisible(in: textView)
        }
    }

    /// The selection is not in one text row: the selection responder takes the keyboard, and no row is pinned.
    /// Select All does not scroll, like a system text view. Other selections show their end row.
    func focusOutsideRows() {
        list.pinnedItem = nil
        let row = model.selection.end.blockIndex
        if row < model.rowCount, !selectsWholeDocument {
            list.scrollToItem(items(forRow: row).lowerBound, rect: nil) {}
        }
        if !responder.isFirstResponder { responder.becomeFirstResponder() }
    }

    private var selectsWholeDocument: Bool {
        let selection = model.selection
        let last = model.rowCount - 1
        return selection.start == RichPosition(blockIndex: 0, offset: 0)
            && selection.end == RichPosition(blockIndex: last, offset: model.row(at: last).block.length)
    }

    /// An arrow left the selection through `edge`: the caret goes into the row before or after.
    /// A divider or raw block there is selected whole.
    func moveSelection(fromRow row: Int, through edge: RichTextView.Edge) {
        let isBackward = edge == .up || edge == .start
        let target = isBackward ? row - 1 : row + 1
        guard target >= 0, target < model.rowCount else { return }
        let block = model.row(at: target).block
        if block.plainText == nil {
            model.select(.range(0..<1, inBlock: target))
        } else {
            model.select(.caret(RichPosition(blockIndex: target, offset: isBackward ? block.length : 0)))
        }
    }

    /// Focus left the selection responder or a text view. The flag drops when no view of the list has the keyboard,
    /// unless a focused text view was replaced: then the row's new text view takes the keyboard.
    func focusMayHaveLeft() {
        Task { @MainActor [weak self] in
            guard let self, !hasKeyboardFocus, !isRefocusPending else { return }
            list.pinnedItem = nil
            model.setFocused(false)
        }
    }

    /// Selects a divider or raw block as a whole.
    func selectAtomic(row: Int) {
        model.setFocused(true)
        model.select(.range(0..<1, inBlock: row))
    }

    /// A tap below the last row: the caret goes to the end, after an empty paragraph when the last row has no text.
    func placeCaretAtEnd() {
        model.setFocused(true)
        model.placeCaretAtEnd()
        focusSelection()
    }

    /// The caret stays on screen without animation, also after the list got shorter (the keyboard came up).
    func scrollCaretToVisible(in textView: RichTextView) {
        guard let position = textView.selectedTextRange?.end else { return }
        let caret = textView.convert(textView.caretRect(for: position), to: list.view)
        guard caret.minY.isFinite, caret.height > 0 else { return }
        list.view.scrollRectToVisible(caret.insetBy(dx: 0, dy: -8), animated: false)
    }

    /// After each layout pass: when the list got shorter, the focused caret stays visible.
    func didLayout() {
        updateKeyboardInset()
        let height = list.view.bounds.height
        defer { lastListHeight = height }
        guard height < lastListHeight, let item = list.pinnedItem, let textView = textView(forItem: item), textView.isFirstResponder else {
            return
        }
        scrollCaretToVisible(in: textView)
    }

    /// A tap in the list below the last row.
    @objc func listTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: list.view)
        guard list.item(at: point) == nil, point.y >= 0 else { return }
        placeCaretAtEnd()
    }
}

// MARK: - RichTextRowHost

extension RichRowAdapter: RichTextRowHost {
    func row(of textView: RichTextView) -> Int? {
        item(containing: textView).map { row(forItem: $0).row }
    }

    func textViewDidChangeHeight(_ textView: RichTextView) {
        guard let item = item(containing: textView) else { return }
        list.invalidateHeight(ofItem: item)
    }

    func textView(_ textView: RichTextView, didLeaveThrough edge: RichTextView.Edge) {
        guard let row = row(of: textView) else { return }
        moveSelection(fromRow: row, through: edge)
    }

    var canExtendSelectionPastEdge: Bool {
        selectionHandler != nil
    }

    func textView(_ textView: RichTextView, didShiftArrowAtEdge edge: RichTextView.Edge) {
        guard let row = row(of: textView) else { return }
        selectionHandler?.extendSelection(fromRow: row, through: edge)
    }

    func textViewDidBeginEditing(_ textView: RichTextView) {
        editingTextView = textView
        model.setFocused(true)
        if let item = item(containing: textView) { list.pinnedItem = item }
    }

    /// Focus may move to another row or the responder in the same turn. The flag drops only when none has it.
    /// A new nesting level changes the row's view tree, so SwiftUI replaces its text view. A replaced view
    /// has left the window: the row's new text view then takes the focus.
    func textViewDidEndEditing(_ textView: RichTextView) {
        focusMayHaveLeft()
    }

    func textViewDidRequestSelectAll(_ textView: RichTextView) {
        if let selectionHandler {
            selectionHandler.selectAll()
        } else {
            model.selectAll()
        }
    }

    /// A new nesting level or heading changes the row's view tree, so SwiftUI replaces its text view.
    /// The new view exists after this update, so the focus moves one turn later.
    func textViewWillBeRemoved(_ textView: RichTextView, hadFocus: Bool) {
        // Off screen, the whole editor is leaving. It must not keep the keyboard.
        guard hadFocus, model.isFocused, list.view.window != nil else { return }
        isRefocusPending = true
        // The keyboard stays up until the new text view takes it. Without a first responder the keyboard
        // hides, the bottom inset drops and the list offset jumps.
        if !responder.isFirstResponder { responder.becomeFirstResponder() }
        Task { @MainActor [weak self] in
            guard let self else { return }
            isRefocusPending = false
            guard list.view.window != nil else { return }
            focusSelection()
        }
    }

    /// True while a view inside the list is first responder.
    var hasKeyboardFocus: Bool {
        guard let responder = list.view.window?.findFirstResponder() else { return false }
        return responder.isDescendant(of: list.view)
    }
}

private extension UIView {
    /// The first responder in this view's tree, if any.
    func findFirstResponder() -> UIView? {
        if isFirstResponder { return self }
        for subview in subviews {
            if let found = subview.findFirstResponder() { return found }
        }
        return nil
    }
}
