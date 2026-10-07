import Foundation

/// Identity of a row. It stays the same while the row is edited, so a view can keep its text view.
struct RichRowID: Hashable, Sendable {
    let value: Int
}

/// One block with its identity.
struct RichRow: Equatable, Sendable {
    let id: RichRowID
    var block: RichBlock
}

/// Undo and redo as replaced rows, not whole documents. A step costs memory only for the rows it changed.
struct RichUndoStack: Sendable {
    struct Step: Sendable {
        /// Indexes, in the document after the change, of the rows the change put in.
        var range: Range<Int>
        /// The rows that were there before the change.
        var rows: [RichRow]
        /// The selection before the change. Undo puts it back.
        var selection: RichSelection
        /// An open typing burst: more keys in the same row join this step.
        var typingRowID: RichRowID?
    }

    private let capacity: Int
    private(set) var undoSteps: [Step] = []
    private(set) var redoSteps: [Step] = []

    init(capacity: Int = 100) {
        self.capacity = max(1, capacity)
    }

    var canUndo: Bool { !undoSteps.isEmpty }
    var canRedo: Bool { !redoSteps.isEmpty }

    /// The open typing burst's row, if any.
    var typingRowID: RichRowID? { undoSteps.last?.typingRowID }

    /// Records a change. Clears redo.
    mutating func record(_ step: Step) {
        endTypingBurst()
        undoSteps.append(step)
        if undoSteps.count > capacity { undoSteps.removeFirst() }
        redoSteps.removeAll()
    }

    /// A typing step whose row is typed into again: the step already holds the row as it was before the burst.
    mutating func continueTypingBurst() {
        redoSteps.removeAll()
    }

    /// The last step becomes an open typing burst in `rowID`, so the next keys there join it.
    mutating func markLastStepAsTyping(rowID: RichRowID) {
        guard !undoSteps.isEmpty else { return }
        undoSteps[undoSteps.count - 1].typingRowID = rowID
    }

    mutating func endTypingBurst() {
        if undoSteps.last?.typingRowID != nil {
            undoSteps[undoSteps.count - 1].typingRowID = nil
        }
    }

    /// Takes the step to undo. The caller applies it and gives back the inverse with `pushRedo`.
    mutating func popUndo() -> Step? {
        undoSteps.popLast()
    }

    mutating func popRedo() -> Step? {
        redoSteps.popLast()
    }

    mutating func pushRedo(_ step: Step) {
        redoSteps.append(step)
    }

    /// The inverse of a redone step. It keeps redo, unlike `record`.
    mutating func pushUndo(_ step: Step) {
        undoSteps.append(step)
        if undoSteps.count > capacity { undoSteps.removeFirst() }
    }
}
