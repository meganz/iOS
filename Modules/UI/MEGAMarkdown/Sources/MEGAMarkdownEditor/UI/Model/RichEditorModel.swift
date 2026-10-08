import Foundation
import Observation

/// What made the model change. The row adapter needs it to tell its own typing from other changes.
enum RichEditorChangeCause: Equatable, Sendable {
    /// The text view of row `row` changed its text. The view already shows the new text.
    case typing(row: Int)
    /// A checkbox tap. The selection does not move, so the keyboard focus and the scroll offset stay.
    case checkbox
    /// Any other edit or a selection change.
    case other
}

/// The rich editor's state on the main actor. It owns one `RichEditor` value and changes it in place,
/// so a key copies no rows. The UI reads one row at a time and never keeps the rows or the document.
///
/// After every action `didMutate` tells the row adapter first, synchronously, so the list is current
/// before SwiftUI draws. Then it sets the observed values, each only when it changed: an unchanged
/// write would still redraw every view that reads it.
@MainActor
@Observable
final class RichEditorModel {
    @ObservationIgnored private(set) var editor: RichEditor
    /// The row adapter. Called after every action, before the observed values change.
    @ObservationIgnored var onEditorChange: ((RichEditorChangeCause) -> Void)?
    /// Gets the Markdown when an export differs from the last one. The binding is the save channel.
    @ObservationIgnored var onExport: ((String) -> Void)?
    /// Runs the export job of the idle save. Tests replace it to hold the export while they edit.
    @ObservationIgnored var runExport: @Sendable (RichExportJob) async -> RichExportResult = { await RichEditorModel.run($0) }
    /// True while the editing text view holds marked text of an input method. The idle save waits for it.
    @ObservationIgnored var hasMarkedText: () -> Bool = { false }

    /// What the formatting toolbar shows.
    private(set) var toolbar: RichToolbarState
    /// `RichEditor.version`: grows on every content change. The idle save restarts on each change.
    private(set) var editVersion: Int
    /// True while a row or the selection responder has the keyboard. The toolbar buttons are enabled only then.
    private(set) var isFocused = false
    /// The link dialog is open on this target with this first content.
    private(set) var linkDialog: RichLinkDialog?

    init(editor: RichEditor) {
        self.editor = editor
        toolbar = RichToolbarState(editor: editor)
        editVersion = editor.version
    }

    // MARK: - Reading

    var rowCount: Int { editor.rows.count }

    func row(at index: Int) -> RichRow {
        editor.rows[index]
    }

    var selection: RichSelection { editor.selection }
    var version: Int { editor.version }
    var lastChange: RichEditor.RowChange? { editor.lastChange }
    var typingStyles: Set<RichSpanStyle> { editor.typingStyles }
    var canUndo: Bool { editor.canUndo }
    var canRedo: Bool { editor.canRedo }

    /// O(rows). Read it once per change.
    func orderedNumbers() -> [Int?] {
        editor.orderedNumbers()
    }

    /// O(rows) plus a small parse per definition block. Read it once per change.
    var referenceDefinitionSource: String {
        editor.referenceDefinitionSource
    }

    /// True when `markdown` is the loaded text or the last export, so the binding write was our own save.
    func holds(_ markdown: String) -> Bool {
        editor.holds(markdown)
    }

    // MARK: - Changes

    /// Runs one action on the editor, then tells the adapter and updates the observed values.
    func mutate(cause: RichEditorChangeCause = .other, _ action: (inout RichEditor) -> Void) {
        action(&editor)
        didMutate(cause: cause)
    }

    private func didMutate(cause: RichEditorChangeCause) {
        onEditorChange?(cause)
        let newToolbar = RichToolbarState(editor: editor)
        if toolbar != newToolbar { toolbar = newToolbar }
        if editVersion != editor.version { editVersion = editor.version }
    }

    func setFocused(_ focused: Bool) {
        if isFocused != focused { isFocused = focused }
    }

    func setLinkDialog(_ dialog: RichLinkDialog?) {
        if linkDialog != dialog { linkDialog = dialog }
    }

    // MARK: - Save

    /// The idle save: ends the typing burst, exports off the main thread, and writes when the export changed.
    /// A key during the export makes the result stale. `finishExport` drops it, and the next idle save covers the key.
    func idle() async {
        editor.endTypingBurst()
        guard editor.hasUnexportedChanges else { return }
        let result = await runExport(editor.makeExportJob())
        // A cancelled save belongs to a view that is gone, for example after an outside text replaced the editor.
        guard !Task.isCancelled else { return }
        if let markdown = editor.finishExport(result) {
            onExport?(markdown)
        }
    }

    /// Exports now on the main thread: mode switch, disappear, background. Also while an idle export runs:
    /// that result is then dropped by version.
    func exportChanges() {
        if let markdown = editor.exportChanges() {
            onExport?(markdown)
        }
    }

    @concurrent
    fileprivate nonisolated static func run(_ job: RichExportJob) async -> RichExportResult {
        job.run()
    }
}

/// The link dialog's target and what it shows first.
struct RichLinkDialog: Equatable, Sendable {
    let target: RichLinkTarget
    let draft: RichLinkDraft
}
