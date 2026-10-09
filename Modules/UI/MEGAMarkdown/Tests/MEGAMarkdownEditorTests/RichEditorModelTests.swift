import Foundation
@testable import MEGAMarkdownEditor
import Observation
import Testing

@MainActor
@Suite struct RichEditorModelTests {
    /// A model on a loaded file, with every export recorded.
    @MainActor
    private final class Harness {
        let model: RichEditorModel
        var writes: [String] = []
        var changes: [RichEditorChangeCause] = []

        /// The writes without the last line end, which an edited file may gain.
        var lines: [String] { writes.map { $0.trimmingCharacters(in: .newlines) } }

        init(markdown: String) {
            model = RichEditorModel(editor: RichEditor(markdown: markdown))
            model.onExport = { [weak self] in self?.writes.append($0) }
            model.onEditorChange = { [weak self] in self?.changes.append($0) }
        }
    }

    /// True when reading `value` from the model and then running `change` notifies an observer.
    private func notifies(_ read: @escaping () -> Void, when change: () -> Void) -> Bool {
        let fired = Flag()
        withObservationTracking(read) { fired.isSet = true }
        change()
        return fired.isSet
    }

    /// Observation calls back synchronously inside `change`, on the main thread. The box only crosses the
    /// `@Sendable` closure type, never a thread.
    private final class Flag: @unchecked Sendable {
        var isSet = false
    }

    @Test func typingTellsTheAdapterWhichRowTyped() {
        let harness = Harness(markdown: "abc")
        harness.model.replaceText(inRow: 0, range: 3..<3, with: "x")
        harness.model.insertParagraphBreak()
        #expect(harness.changes == [.typing(row: 0), .other])
        #expect(harness.model.row(at: 0).block == paragraph("abcx"))
        #expect(harness.model.rowCount == 2)
    }

    /// The adapter runs before the observed values change, so the list is current when SwiftUI draws.
    @Test func adapterRunsBeforeObservedValuesChange() {
        let harness = Harness(markdown: "abc")
        var seen: (version: Int, editVersion: Int)?
        harness.model.onEditorChange = { [model = harness.model] _ in seen = (model.version, model.editVersion) }
        harness.model.replaceText(inRow: 0, range: 0..<0, with: "x")
        #expect(seen?.version == 1)
        #expect(seen?.editVersion == 0)
        #expect(harness.model.editVersion == 1)
    }

    @Test func aKeyDoesNotRepublishAnUnchangedToolbar() {
        let model = Harness(markdown: "abc").model
        #expect(!notifies({ _ = model.toolbar }, when: { model.replaceText(inRow: 0, range: 3..<3, with: "x") }))
        #expect(notifies({ _ = model.editVersion }, when: { model.replaceText(inRow: 0, range: 4..<4, with: "y") }))
    }

    @Test func aCaretMoveDoesNotChangeTheEditVersion() {
        let model = Harness(markdown: "abc\n\n**bold**").model
        #expect(!notifies({ _ = model.editVersion }, when: { model.select(.caret(position(0, 1))) }))
        #expect(notifies({ _ = model.toolbar }, when: { model.select(.caret(position(1, 2))) }))
        #expect(model.toolbar.activeStyles == [.bold])
    }

    @Test func focusPublishesOnlyChanges() {
        let model = Harness(markdown: "abc").model
        #expect(notifies({ _ = model.isFocused }, when: { model.setFocused(true) }))
        #expect(!notifies({ _ = model.isFocused }, when: { model.setFocused(true) }))
    }

    // MARK: - Links

    @Test func linkDialogSavesAValidURLAndCloses() {
        let model = Harness(markdown: "go here").model
        model.select(.range(3..<7, inBlock: 0))
        model.beginLinkEditing()
        #expect(model.linkDialog?.draft == RichLinkDraft(url: "", text: "here", isEditing: false))
        #expect(!model.saveLink(urlText: "not a url", label: "here"))
        #expect(model.linkDialog != nil)
        #expect(model.saveLink(urlText: "https://mega.nz", label: "here"))
        #expect(model.linkDialog == nil)
        #expect(model.row(at: 0).block == paragraph("go here", (3..<7, link("https://mega.nz"))))
        // A tap with the caret after the link edits it, so the button shows as on.
        #expect(model.toolbar.isLinkOn)
        model.select(.caret(position(0, 1)))
        #expect(!model.toolbar.isLinkOn)
    }

    @Test func linkDialogRemovesALink() {
        let model = Harness(markdown: "[here](https://mega.nz)").model
        model.select(.caret(position(0, 2)))
        model.beginLinkEditing()
        #expect(model.linkDialog?.draft.isEditing == true)
        model.removeLink()
        #expect(model.linkDialog == nil)
        #expect(model.row(at: 0).block == paragraph("here"))
    }

    // MARK: - Save

    @Test func idleExportsOnceAndEndsTheTypingBurst() async {
        let harness = Harness(markdown: "a")
        harness.model.replaceText(inRow: 0, range: 1..<1, with: "b")
        await harness.model.idle()
        #expect(harness.lines == ["ab"])
        await harness.model.idle()
        #expect(harness.lines == ["ab"])
        harness.model.replaceText(inRow: 0, range: 2..<2, with: "c")
        harness.model.undo()
        #expect(harness.model.row(at: 0).block == paragraph("ab"))
    }

    @Test func idleWithoutAnEditWritesNothing() async {
        let harness = Harness(markdown: "# Title\r\n\r\nSome *text*\r\n")
        await harness.model.idle()
        harness.model.exportChanges()
        #expect(harness.writes.isEmpty)
    }

    /// Holds the idle export until the test opens the gate, so the test edits while the export waits.
    @MainActor
    private final class ExportGate {
        private(set) var hasStarted = false
        private var isOpen = false
        private var continuation: CheckedContinuation<Void, Never>?

        func wait() async {
            hasStarted = true
            if isOpen { return }
            await withCheckedContinuation { continuation = $0 }
        }

        func open() {
            isOpen = true
            continuation?.resume()
            continuation = nil
        }
    }

    /// Starts an idle save that waits at the gate. Returns when its export has started.
    private func startHeldIdle(_ model: RichEditorModel, gate: ExportGate) async throws -> Task<Void, Never> {
        model.runExport = { job in
            await gate.wait()
            return job.run()
        }
        let idle = Task { await model.idle() }
        try await waitUntil("the idle export to start") { gate.hasStarted }
        return idle
    }

    /// A save on disappear during an idle export writes the newest text. The late idle result is stale and dropped.
    @Test func exportDuringAnIdleExportWinsAndTheIdleResultIsDropped() async throws {
        let harness = Harness(markdown: "a")
        let gate = ExportGate()
        harness.model.replaceText(inRow: 0, range: 1..<1, with: "b")
        let idle = try await startHeldIdle(harness.model, gate: gate)
        harness.model.replaceText(inRow: 0, range: 2..<2, with: "c")
        harness.model.exportChanges()
        #expect(harness.lines == ["abc"])
        gate.open()
        await idle.value
        #expect(harness.lines == ["abc"])
    }

    /// A key during the idle export makes its result stale. Nothing is written, and the next idle save covers the key.
    @Test func keyDuringAnIdleExportDropsItsResultAndTheNextIdleSaveWritesIt() async throws {
        let harness = Harness(markdown: "a")
        let gate = ExportGate()
        harness.model.replaceText(inRow: 0, range: 1..<1, with: "b")
        let idle = try await startHeldIdle(harness.model, gate: gate)
        harness.model.replaceText(inRow: 0, range: 2..<2, with: "c")
        gate.open()
        await idle.value
        #expect(harness.writes.isEmpty)
        await harness.model.idle()
        #expect(harness.lines == ["abc"])
    }

    @Test func ownExportIsHeld() throws {
        let harness = Harness(markdown: "a")
        harness.model.replaceText(inRow: 0, range: 1..<1, with: "b")
        harness.model.exportChanges()
        let written = try #require(harness.writes.first)
        #expect(harness.model.holds(written))
        #expect(!harness.model.holds("other"))
    }

    /// The loaded text is an echo of the load only until the first export is given out. Later it is a revert from outside.
    @Test func loadedTextIsHeldOnlyBeforeTheFirstExport() {
        let harness = Harness(markdown: "a")
        #expect(harness.model.holds("a"))
        harness.model.replaceText(inRow: 0, range: 1..<1, with: "b")
        harness.model.exportChanges()
        #expect(!harness.model.holds("a"))
    }

    /// A save that was cancelled, for example because outside text replaced the editor, must not write to the binding.
    @Test func cancelledIdleSaveDoesNotWrite() async throws {
        let harness = Harness(markdown: "a")
        let gate = ExportGate()
        harness.model.replaceText(inRow: 0, range: 1..<1, with: "b")
        let idle = try await startHeldIdle(harness.model, gate: gate)
        idle.cancel()
        gate.open()
        await idle.value
        #expect(harness.writes.isEmpty)
    }

    // MARK: - Undo manager

    @Test func undoManagerForwardsToTheModel() {
        let model = Harness(markdown: "a").model
        let manager = ModelUndoManager(model: model)
        #expect(!manager.canUndo)
        model.replaceText(inRow: 0, range: 1..<1, with: "b")
        #expect(manager.canUndo)
        manager.undo()
        #expect(model.row(at: 0).block == paragraph("a"))
        #expect(manager.canRedo)
        manager.redo()
        #expect(model.row(at: 0).block == paragraph("ab"))
    }

    /// A text view's own registrations never build a second stack.
    @Test func undoManagerIgnoresRegistrations() {
        let model = Harness(markdown: "a").model
        let manager = ModelUndoManager(model: model)
        manager.beginUndoGrouping()
        manager.registerUndo(withTarget: manager) { _ in Issue.record("a registered action ran") }
        manager.endUndoGrouping()
        #expect(!manager.canUndo)
        manager.undo()
        #expect(model.row(at: 0).block == paragraph("a"))
    }

    @Test func undoManagerIsHiddenWhileTextIsMarked() {
        let manager = ModelUndoManager(model: Harness(markdown: "a").model)
        #expect(manager.forTextView(hasMarkedText: true) == nil)
        #expect(manager.forTextView(hasMarkedText: false) === manager)
    }
}
