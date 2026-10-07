@testable import MEGAMarkdownEditor
import Testing

@Suite("Undo stack")
struct RichUndoStackTests {
    private func step(_ id: Int) -> RichUndoStack.Step {
        RichUndoStack.Step(range: id..<(id + 1), rows: [], selection: .caret(position(0, 0)))
    }

    @Test func startsEmpty() {
        let stack = RichUndoStack()
        #expect(!stack.canUndo)
        #expect(!stack.canRedo)
    }

    @Test func dropsTheOldestStepAtCapacity() {
        var stack = RichUndoStack(capacity: 2)
        stack.record(step(1))
        stack.record(step(2))
        stack.record(step(3))
        #expect(stack.undoSteps.map(\.range) == [2..<3, 3..<4])
    }

    @Test func capacityIsAtLeastOne() {
        var stack = RichUndoStack(capacity: 0)
        stack.record(step(1))
        stack.record(step(2))
        #expect(stack.undoSteps.map(\.range) == [2..<3])
    }

    @Test func recordClearsRedo() {
        var stack = RichUndoStack()
        stack.record(step(1))
        let undone = stack.popUndo()
        stack.pushRedo(undone!)
        #expect(stack.canRedo)
        stack.record(step(2))
        #expect(!stack.canRedo)
    }

    @Test func pushUndoKeepsRedo() {
        var stack = RichUndoStack()
        stack.pushRedo(step(1))
        stack.pushRedo(step(2))
        stack.pushUndo(step(3))
        #expect(stack.redoSteps.count == 2)
        #expect(stack.undoSteps.count == 1)
    }

    @Test func popsInLastInFirstOutOrder() {
        var stack = RichUndoStack()
        stack.record(step(1))
        stack.record(step(2))
        #expect(stack.popUndo()?.range == 2..<3)
        #expect(stack.popUndo()?.range == 1..<2)
        #expect(stack.popUndo() == nil)
    }

    @Test func typingBurstIsMarkedAndEnded() {
        var stack = RichUndoStack()
        let row = RichRowID(value: 7)
        stack.record(step(1))
        stack.markLastStepAsTyping(rowID: row)
        #expect(stack.typingRowID == row)
        stack.endTypingBurst()
        #expect(stack.typingRowID == nil)
    }

    @Test func recordEndsTheOpenTypingBurst() {
        var stack = RichUndoStack()
        stack.record(step(1))
        stack.markLastStepAsTyping(rowID: RichRowID(value: 7))
        stack.record(step(2))
        #expect(stack.undoSteps.first?.typingRowID == nil)
    }

    @Test func continuingABurstClearsRedoAndKeepsTheBurstOpen() {
        var stack = RichUndoStack()
        let row = RichRowID(value: 7)
        stack.record(step(1))
        stack.markLastStepAsTyping(rowID: row)
        stack.pushRedo(step(2))
        stack.continueTypingBurst()
        #expect(!stack.canRedo)
        #expect(stack.typingRowID == row)
    }

    @Test func markingAnEmptyStackDoesNothing() {
        var stack = RichUndoStack()
        stack.markLastStepAsTyping(rowID: RichRowID(value: 1))
        #expect(stack.typingRowID == nil)
    }
}
