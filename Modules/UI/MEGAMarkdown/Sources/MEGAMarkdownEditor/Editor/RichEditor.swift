import Foundation

/// The rich mode editor without UI: rows, selection, typing styles, undo, clipboard and export.
///
/// A value type. The UI keeps one, calls its methods for each user action, and shows `rows` and `selection`.
/// Every method is synchronous and safe off the main thread, so a load can run in a background task.
/// The jobs live in extensions: `+Text`, `+Formatting`, `+Links`, `+Clipboard`, `+Undo`. Export is in `RichExportState.swift`.
struct RichEditor: Sendable {
    /// What the last edit changed: `oldRange` rows were replaced by `newCount` rows at the same start.
    /// A list view can reload just these rows.
    struct RowChange: Equatable, Sendable {
        let oldRange: Range<Int>
        let newCount: Int
    }

    private(set) var rows: [RichRow]
    /// Never empty. Indexes are valid for `rows`.
    private(set) var selection: RichSelection
    /// Styles that typed text gets. They follow the caret. A style toggle at a caret changes them.
    private(set) var typingStyles: Set<RichSpanStyle> = []
    private(set) var lastChange: RowChange?
    /// Grows on every content change.
    private(set) var version = 0

    let format: RichFileFormat
    var undoStack = RichUndoStack()
    var export: RichExportState
    private var nextRowID = 0

    /// Opens an existing file. An untouched file never exports.
    /// Loads synchronously. A large text takes tens of ms, so call it from a background task.
    init(markdown: String) {
        let loaded = RichMarkdownConverter.load(markdown)
        self.init(document: loaded.document, export: RichExportState(loadedMarkdown: markdown, loaded: loaded))
    }

    /// Starts a new file from a document, for example a template. Its first export counts as a change.
    /// An empty document exports the empty text, which is not a change.
    init(newFile document: RichDocument) {
        let state = RichExportState(loadedMarkdown: "", exported: "", cache: InlineExportCache(), exportedVersion: -1)
        self.init(document: document, export: state)
    }

    private init(document: RichDocument, export: RichExportState) {
        let blocks = document.blocks.isEmpty ? [.paragraph(RichText())] : document.blocks
        rows = blocks.indices.map { RichRow(id: RichRowID(value: $0), block: blocks[$0]) }
        nextRowID = blocks.count
        format = document.format
        selection = .caret(RichPosition(blockIndex: 0, offset: 0))
        self.export = export
    }

    var document: RichDocument {
        RichDocument(blocks: rows.map(\.block), format: format)
    }

    func index(of rowID: RichRowID) -> Int? {
        rows.firstIndex { $0.id == rowID }
    }

    var canUndo: Bool { undoStack.canUndo }
    var canRedo: Bool { undoStack.canRedo }

    /// The number each ordered item shows. nil for other rows. O(rows), so a view should ask once per change.
    func orderedNumbers() -> [Int?] {
        RichDocument.orderedNumbers(of: rows.lazy.map(\.block))
    }

    // MARK: - Selection

    /// The UI reports a caret move or a new selection. A caret picks up the styles of the text before it.
    mutating func select(_ newSelection: RichSelection) {
        let moved = clamped(newSelection)
        if moved.start.blockIndex != selection.start.blockIndex || !moved.isCaret {
            undoStack.endTypingBurst()
        }
        selection = moved
        refreshTypingStyles()
    }

    mutating func selectAll() {
        select(document.wholeSelection)
    }

    /// Tap below the last block: the caret goes to the end of the last text block.
    /// After a code, divider or raw block, an empty paragraph is added to type in.
    mutating func placeCaretAtEnd() {
        guard let last = rows.last, last.block.richText != nil else {
            var blocks = rows.map(\.block)
            blocks.append(.paragraph(RichText()))
            commit(blocks, caret: RichPosition(blockIndex: blocks.count - 1, offset: 0))
            return
        }
        select(.caret(RichPosition(blockIndex: rows.count - 1, offset: last.block.length)))
    }

    mutating func refreshTypingStyles() {
        guard selection.isCaret, let text = rows[selection.start.blockIndex].block.richText else {
            if selection.isCaret { typingStyles = [] }
            return
        }
        typingStyles = text.styles(in: selection.start.offset..<selection.start.offset)
    }

    mutating func setTypingStyles(_ styles: Set<RichSpanStyle>) {
        typingStyles = styles
    }

    // MARK: - Committing changes

    /// Replaces the document and records one undo step. Rows that did not change keep their identity.
    /// Unchanged rows compare in O(1): their text storage is shared with the old rows.
    mutating func commit(_ blocks: [RichBlock], caret: RichPosition) {
        // A join or a removed parent can leave a list item deeper than Markdown can write. One linear pass fixes it.
        var normalized = RichDocument(blocks: blocks.isEmpty ? [.paragraph(RichText())] : blocks)
        normalized.normalizeListIndents(in: 0..<normalized.blocks.count)
        let newBlocks = normalized.blocks
        var prefix = 0
        while prefix < rows.count, prefix < newBlocks.count, rows[prefix].block == newBlocks[prefix] {
            prefix += 1
        }
        var suffix = 0
        while suffix < rows.count - prefix, suffix < newBlocks.count - prefix,
              rows[rows.count - 1 - suffix].block == newBlocks[newBlocks.count - 1 - suffix] {
            suffix += 1
        }
        let oldRange = prefix..<(rows.count - suffix)
        let newRange = prefix..<(newBlocks.count - suffix)
        guard !oldRange.isEmpty || !newRange.isEmpty else {
            select(.caret(caret))
            return
        }
        undoStack.record(RichUndoStack.Step(range: newRange, rows: Array(rows[oldRange]), selection: selection))
        replaceRows(oldRange, with: Array(newBlocks[newRange]))
        selection = clamped(.caret(caret))
        refreshTypingStyles()
    }

    /// Replaced rows keep the old identities in order, so the row being edited keeps its text view.
    mutating func replaceRows(_ oldRange: Range<Int>, with blocks: [RichBlock]) {
        let newRows = blocks.enumerated().map { offset, block in
            RichRow(id: offset < oldRange.count ? rows[oldRange.lowerBound + offset].id : makeRowID(), block: block)
        }
        rows.replaceSubrange(oldRange, with: newRows)
        lastChange = RowChange(oldRange: oldRange, newCount: newRows.count)
        version += 1
    }

    /// Puts rows back as they were, with their identities. For undo and redo.
    mutating func restoreRows(_ range: Range<Int>, with restored: [RichRow]) {
        rows.replaceSubrange(range, with: restored)
        if rows.isEmpty { rows = [RichRow(id: makeRowID(), block: .paragraph(RichText()))] }
        lastChange = RowChange(oldRange: range, newCount: restored.count)
        version += 1
    }

    /// One row's block changed in place (typing). No row moves.
    mutating func updateBlock(at index: Int, to block: RichBlock) {
        rows[index].block = block
        lastChange = RowChange(oldRange: index..<(index + 1), newCount: 1)
        version += 1
    }

    mutating func setSelectionWithoutStyleRefresh(_ newSelection: RichSelection) {
        selection = clamped(newSelection)
    }

    func clamped(_ position: RichPosition) -> RichPosition {
        let index = max(0, min(position.blockIndex, rows.count - 1))
        return RichPosition(blockIndex: index, offset: rows[index].block.clampedOffset(position.offset))
    }

    func clamped(_ selection: RichSelection) -> RichSelection {
        RichSelection(start: clamped(selection.start), end: clamped(selection.end))
    }

    private mutating func makeRowID() -> RichRowID {
        defer { nextRowID += 1 }
        return RichRowID(value: nextRowID)
    }
}
