import Foundation

extension RichEditor {
    /// Puts back the rows and the selection from before the last change.
    mutating func undo() {
        guard let step = undoStack.popUndo() else { return }
        undoStack.pushRedo(inverse(of: step))
        restoreRows(step.range, with: step.rows)
        setSelectionWithoutStyleRefresh(step.selection)
        refreshTypingStyles()
    }

    mutating func redo() {
        guard let step = undoStack.popRedo() else { return }
        undoStack.pushUndo(inverse(of: step))
        restoreRows(step.range, with: step.rows)
        setSelectionWithoutStyleRefresh(step.selection)
        refreshTypingStyles()
    }

    /// Ends the open typing burst, so the next key starts a new undo step. The UI calls it after a pause.
    mutating func endTypingBurst() {
        undoStack.endTypingBurst()
    }

    /// The step that takes the document back to how it is now.
    private func inverse(of step: RichUndoStack.Step) -> RichUndoStack.Step {
        RichUndoStack.Step(
            range: step.range.lowerBound..<(step.range.lowerBound + step.rows.count),
            rows: Array(rows[step.range]),
            selection: selection,
            typingRowID: nil
        )
    }
}
