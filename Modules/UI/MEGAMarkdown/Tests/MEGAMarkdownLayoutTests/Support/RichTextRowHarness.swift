import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Observation
import SwiftUI
import UIKit

/// One `RichTextRow` in a window, for model row `row`, with a host that records what the row reports.
/// The window is visible but never the key window, so the text view never takes the focus.
/// Typing goes through the text view delegate, the same path as with the focus.
@MainActor
final class RichTextRowHarness: RichTextRowHost {
    @Observable
    @MainActor
    final class Input {
        var block: RichBlock
        var version: Int

        init(block: RichBlock, version: Int) {
            self.block = block
            self.version = version
        }
    }

    private struct Host: View {
        let input: Input
        weak var host: RichTextRowHarness?

        var body: some View {
            RichTextRow(block: input.block, version: input.version, theme: .default, strings: .english, host: host)
                .frame(width: 300)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    let model: RichEditorModel
    let modelUndoManager: ModelUndoManager
    let row: Int
    let input: Input
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 600))
    var changes: [RichEditorChangeCause] = []
    var heightChanges = 0
    var leftThrough: [RichTextView.Edge] = []
    var shiftArrows: [RichTextView.Edge] = []

    init(blocks: [RichBlock], row: Int = 0) {
        var editor = RichEditor(newFile: RichDocument(blocks: blocks))
        editor.select(.caret(RichPosition(blockIndex: row, offset: 0)))
        model = RichEditorModel(editor: editor)
        modelUndoManager = ModelUndoManager(model: model)
        self.row = row
        input = Input(block: blocks[row], version: model.version)
        model.onEditorChange = { [weak self] in self?.changes.append($0) }
        UIView.setAnimationsEnabled(false)
        window.rootViewController = UIHostingController(rootView: Host(input: input, host: self))
        window.isHidden = false
        flushLayout()
    }

    func close() {
        window.isHidden = true
        window.rootViewController = nil
    }

    var textView: RichTextView? {
        var pending: [UIView] = [window]
        while let view = pending.popLast() {
            if let textView = view as? RichTextView { return textView }
            pending.append(contentsOf: view.subviews)
        }
        return nil
    }

    /// The row input again, from the model now, like a list cell that is configured again.
    func reconfigure() {
        input.block = model.row(at: row).block
        input.version = model.version
    }

    /// Types like the keyboard: it asks the delegate first. A programmatic `insertText` does not.
    func type(_ text: String, into textView: RichTextView) {
        let range = textView.selectedRange
        if textView.delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true {
            textView.insertText(text)
        }
    }

    /// Lets SwiftUI draw the row with the newest input. The layout pass runs the SwiftUI update.
    func flushLayout() {
        window.layoutIfNeeded()
        window.layoutIfNeeded()
    }

    // MARK: - RichTextRowHost

    func row(of textView: RichTextView) -> Int? { row }
    func textViewDidChangeHeight(_ textView: RichTextView) { heightChanges += 1 }
    func textView(_ textView: RichTextView, didLeaveThrough edge: RichTextView.Edge) { leftThrough.append(edge) }
    var canExtendSelectionPastEdge: Bool { true }
    func textView(_ textView: RichTextView, didShiftArrowAtEdge edge: RichTextView.Edge) { shiftArrows.append(edge) }
    func textViewDidBeginEditing(_ textView: RichTextView) { model.setFocused(true) }
    func textViewDidEndEditing(_ textView: RichTextView) { model.setFocused(false) }
    func textViewWillBeRemoved(_ textView: RichTextView, hadFocus: Bool) {}
    func textViewDidRequestSelectAll(_ textView: RichTextView) { model.selectAll() }
}
