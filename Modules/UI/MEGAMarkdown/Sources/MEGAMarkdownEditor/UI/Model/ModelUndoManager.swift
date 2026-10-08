import Foundation

/// The undo manager every rich row text view returns. UIKit reads undo only through `UIResponder.undoManager`,
/// so ⌘Z, ⇧⌘Z, shake, 3-finger swipe and the iPad shortcut bar all reach the model's undo stack.
@MainActor
final class ModelUndoManager: UndoManager {
    weak var model: RichEditorModel?

    init(model: RichEditorModel) {
        self.model = model
        super.init()
        // The text view must not build its own stack. Disabled registration drops every action it records.
        groupsByEvent = false
        disableUndoRegistration()
    }

    /// What a text view returns as its undo manager. nil while it has marked text: an undo then would
    /// replace text the input method still owns.
    func forTextView(hasMarkedText: Bool) -> UndoManager? {
        hasMarkedText ? nil : self
    }

    override var canUndo: Bool { model?.canUndo ?? false }
    override var canRedo: Bool { model?.canRedo ?? false }

    override func undo() {
        model?.undo()
    }

    override func redo() {
        model?.redo()
    }

    // UITextView opens and closes groups around each edit. There is no stack here, so there is nothing to group.
    override func beginUndoGrouping() {}
    override func endUndoGrouping() {}
    override var groupingLevel: Int { 0 }
    override func enableUndoRegistration() {}
    override func removeAllActions() {}
    override func removeAllActions(withTarget target: Any) {}
    override func registerUndo(withTarget target: Any, selector: Selector, object anObject: Any?) {}
}
