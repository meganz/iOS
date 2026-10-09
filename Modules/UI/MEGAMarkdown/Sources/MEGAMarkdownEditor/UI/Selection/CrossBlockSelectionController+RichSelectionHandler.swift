import UIKit

// MARK: - RichSelectionHandler

extension CrossBlockSelectionController: RichSelectionHandler {
    /// ⇧ with an arrow at a row edge: the head goes one row further. The anchor stays.
    func extendSelection(fromRow row: Int, through edge: RichTextView.Edge) {
        guard let model = adapter?.model else { return }
        let isDown = edge == .down || edge == .end
        let current = selection ?? Self.directed(model.selection, headAtEnd: isDown)
        guard let next = current.movingHead(down: isDown, rowCount: model.rowCount, length: { model.row(at: $0).block.length }) else {
            return
        }
        // Back inside one text row: that row's text view takes the selection again.
        if !showsLayer(next.range) {
            clear()
        } else {
            selection = next
        }
        model.select(next.range)
        refreshDisplay()
    }

    /// The head of the layer's selection, when it is the model's selection.
    /// The adapter asks before `modelDidChange()`, so after undo the layer may still hold the old selection.
    var selectionHead: RichPosition? {
        guard let selection, selection.range == adapter?.model.selection else { return nil }
        return selection.head
    }

    /// The model replaces the selection over rows with the text.
    func insertText(_ text: String) -> Bool { false }

    /// The model deletes the selection over rows.
    func deleteBackward() -> Bool { false }

    private static func directed(_ range: RichSelection, headAtEnd: Bool) -> CrossBlockSelection {
        headAtEnd
            ? CrossBlockSelection(anchor: range.start, head: range.end)
            : CrossBlockSelection(anchor: range.end, head: range.start)
    }
}
