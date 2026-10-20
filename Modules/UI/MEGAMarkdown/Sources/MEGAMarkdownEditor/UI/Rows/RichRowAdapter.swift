import MEGADesignToken
import MEGAFoundation
import MEGAMarkdown
import SwiftUI
import UIKit

/// Shows the model's rows in a `MarkdownRowList` and applies each model change to it.
/// It keeps what the list shows: the row identities, the item of each row, the estimate facts, the chrome
/// and the raw block renders. It reads the model one row at a time and never keeps the rows.
@MainActor
final class RichRowAdapter: NSObject {
    let model: RichEditorModel
    let modelUndoManager: ModelUndoManager
    /// Side padding of every row. Rows span the full list width and pad their content by this much.
    static let rowSideInset = TokenSpacing._5

    private(set) lazy var list = makeList()
    /// Has the keyboard when the selection has no text view.
    private(set) lazy var responder = makeResponder()

    var theme = MarkdownTheme.default {
        didSet { if theme != oldValue { list.theme = theme; reconfigureVisibleItems() } }
    }
    var strings = MarkdownEditorStrings.english {
        didSet { if strings != oldValue { reconfigureVisibleItems() } }
    }
    var baseURL: URL? {
        didSet { if baseURL != oldValue { reconfigureVisibleItems() } }
    }
    /// A new closure of the same case does not redraw: the host sets it again on every update.
    var imageLoading = MarkdownImageLoading.altTextOnly {
        didSet { if imageLoading.caseIndex != oldValue.caseIndex { reconfigureVisibleItems() } }
    }
    /// Called after each layout pass of the list, after the list keeps its anchor and the caret stays visible.
    var onLayout: (() -> Void)?
    /// Owns selection over rows. Gets the keys a single row cannot handle.
    weak var selectionHandler: (any RichSelectionHandler)? {
        didSet { responder.selectionHandler = selectionHandler }
    }

    private var itemMap: RichItemMap
    private var rowIDs: [RichRowID]
    private var metrics: [RichRowMetrics]
    private var shapes: [RichRowShape]
    private(set) var chrome: RichChromeIndex
    private var rawCache: RichRawRenderCache
    /// The model version the list shows.
    private(set) var appliedVersion: Int
    var lastListHeight: CGFloat = 0
    /// A focused text view was replaced. Its end of editing must not drop the editor's focus.
    var isRefocusPending = false
    /// The last text view that began editing. Only the first responder can hold marked text.
    weak var editingTextView: RichTextView?
    /// Space below the last row, without the keyboard.
    static let bottomInset = TokenSpacing._5
    private(set) lazy var keyboard = makeKeyboardOverlap()
    /// Top of the formatting toolbar in window coordinates. nil when the editor shows no toolbar.
    var toolbarTop: CGFloat? {
        didSet { if toolbarTop != oldValue { updateKeyboardInset() } }
    }

    init(model: RichEditorModel, load: RichEditorLoad) {
        self.model = model
        modelUndoManager = ModelUndoManager(model: model)
        let rows = load.editor.rows
        rowIDs = rows.map(\.id)
        metrics = load.metrics
        shapes = rows.map { RichRowShape(block: $0.block) }
        chrome = load.chrome
        rawCache = RichRawRenderCache(
            raw: rows.compactMap { row in
                if case .rawSource(let source) = row.block { RichRawRenderCache.RawRow(id: row.id, source: source) } else { nil }
            },
            rows: load.rawRows,
            definitions: load.definitions
        )
        appliedVersion = load.editor.version
        itemMap = RichItemMap(itemCounts: [])
        super.init()
        itemMap = RichItemMap(itemCounts: rowIDs.indices.map(itemCount(ofRow:)))
        model.onEditorChange = { [weak self] cause in self?.editorDidChange(cause) }
        model.hasMarkedText = { [weak self] in self?.editingTextView?.markedTextRange != nil }
    }

    private func makeList() -> MarkdownRowList {
        let list = MarkdownRowList(dataSource: self)
        list.view.keyboardDismissMode = .interactive
        // The list keeps its anchor first. Then the caret stays visible, then the next listener runs.
        // A tap below the last row. Text views and checkboxes in rows keep their own touches.
        let tap = UITapGestureRecognizer(target: self, action: #selector(listTapped(_:)))
        tap.cancelsTouchesInView = false
        list.view.addGestureRecognizer(tap)
        let anchorLayout = list.view.onLayout
        list.view.onLayout = { [weak self] in
            anchorLayout?()
            self?.didLayout()
            self?.onLayout?()
        }
        return list
    }

    private func makeKeyboardOverlap() -> KeyboardOverlap {
        let keyboard = KeyboardOverlap()
        keyboard.onChange = { [weak self] in self?.updateKeyboardInset() }
        return keyboard
    }

    /// The last rows can scroll above the keyboard and the toolbar: the bottom inset grows by the part they cover.
    /// The container never sets insets itself, so the editor does.
    func updateKeyboardInset() {
        let overlap = max(keyboard.overlap(with: list.view), toolbarOverlap())
        let bottom = Self.bottomInset + overlap
        guard list.view.contentInset.bottom != bottom else { return }
        list.view.contentInset.bottom = bottom
        list.view.verticalScrollIndicatorInsets.bottom = overlap
        if let item = list.pinnedItem, let textView = textView(forItem: item), textView.isFirstResponder {
            scrollCaretToVisible(in: textView)
        }
    }

    /// The toolbar sits above the keyboard, so it covers at least as much as the keyboard does.
    private func toolbarOverlap() -> CGFloat {
        guard let toolbarTop, let superview = list.view.superview, list.view.window != nil else { return 0 }
        // The frame, not the bounds: the bounds follow the scroll offset and add rounding noise to the inset.
        return max(0, superview.convert(list.view.frame, to: nil).maxY - toolbarTop)
    }

    private func makeResponder() -> RichSelectionResponder {
        let responder = RichSelectionResponder(frame: .zero)
        responder.model = model
        responder.modelUndoManager = modelUndoManager
        responder.onLeave = { [weak self] edge in
            guard let self else { return }
            let selection = model.selection
            moveSelection(fromRow: edge == .up ? selection.start.blockIndex : selection.end.blockIndex, through: edge)
        }
        responder.onShiftArrow = { [weak self] edge in
            guard let self else { return }
            let selection = model.selection
            selectionHandler?.extendSelection(fromRow: edge == .up ? selection.start.blockIndex : selection.end.blockIndex, through: edge)
        }
        responder.onResign = { [weak self] in self?.focusMayHaveLeft() }
        list.view.addSubview(responder)
        return responder
    }

    // MARK: - Lookups

    /// The items of a model row.
    func items(forRow row: Int) -> Range<Int> {
        itemMap.items(forRow: row)
    }

    /// The model row of an item, and which of the row's items it is.
    func row(forItem item: Int) -> (row: Int, piece: Int) {
        itemMap.row(forItem: item)
    }

    /// The row with this identity now. O(rows): only for rare events like a checkbox tap.
    func row(for id: RichRowID) -> Int? {
        rowIDs.firstIndex(of: id)
    }

    /// The text view of an item while its cell exists, else nil.
    func textView(forItem item: Int) -> RichTextView? {
        guard let cell = list.cell(forItem: item) else { return nil }
        var pending: [UIView] = [cell.contentView]
        while let view = pending.popLast() {
            if let textView = view as? RichTextView { return textView }
            pending.append(contentsOf: view.subviews)
        }
        return nil
    }

    /// The item whose cell holds `view`.
    func item(containing view: UIView) -> Int? {
        guard let cell = sequence(first: view, next: \.superview).first(where: { $0 is MarkdownRowCell }) as? MarkdownRowCell else {
            return nil
        }
        return list.view.indexPath(for: cell)?.item
    }

    private func itemCount(ofRow row: Int) -> Int {
        metrics[row] == .raw ? rawCache.itemCount(for: rowIDs[row]) : 1
    }

    // MARK: - Model changes

    /// Applies the model's last change to the list, synchronously, before SwiftUI draws.
    func editorDidChange(_ cause: RichEditorChangeCause) {
        let version = model.version
        defer {
            appliedVersion = version
            selectionHandler?.modelDidChange()
        }
        guard version == appliedVersion + 1, let change = model.lastChange,
              change.oldRange.upperBound <= rowIDs.count,
              change.oldRange.lowerBound + change.newCount <= model.rowCount else {
            if version == appliedVersion {
                selectionDidChange()
            } else {
                reloadAll()
            }
            return
        }
        let newRange = change.oldRange.lowerBound..<(change.oldRange.lowerBound + change.newCount)
        let newRows = newRange.map(model.row(at:))
        let oldIDs = Array(rowIDs[change.oldRange])
        let rawUpdate = rawCache.update(
            removing: oldIDs,
            adding: newRows.compactMap(Self.rawRow),
            allRaw: { [model] in (0..<model.rowCount).compactMap { Self.rawRow(model.row(at: $0)) } },
            definitions: { [model] in model.referenceDefinitionSource }
        )
        guard rawUpdate == .kept else {
            // New link definitions: every raw row is rendered again already.
            reloadAll(rendersRawRows: false)
            return
        }
        let newMetrics = newRows.map { RichRowMetrics(block: $0.block) }
        let newShapes = newRows.map { RichRowShape(block: $0.block) }
        let newCounts = zip(newRows, newMetrics).map { row, metric in metric == .raw ? rawCache.itemCount(for: row.id) : 1 }
        let typedRow: Int? = if case .typing(let row) = cause { row } else { nil }
        let plan = RichChangePlan.make(RichChangePlan.Input(
            appliedVersion: appliedVersion,
            version: version,
            lastChange: change,
            typedRow: typedRow,
            oldIDs: oldIDs,
            newIDs: newRows.map(\.id),
            oldItemCounts: change.oldRange.map { itemMap.items(forRow: $0).count },
            newItemCounts: newCounts,
            oldShapes: Array(shapes[change.oldRange]),
            newShapes: newShapes
        ))
        switch plan {
        case .selectionOnly:
            selectionDidChange()
        case .ownEdit(let row):
            // The text view already shows the text. Only the estimate facts change.
            metrics[row] = newMetrics[0]
        case .replace(let oldRows, _, let keptRows):
            shapes.replaceSubrange(oldRows, with: newShapes)
            replace(oldRows, newRows: newRows, metrics: newMetrics, itemCounts: newCounts, keptRows: keptRows, movesFocus: cause != .checkbox)
        case .reloadAll:
            reloadAll()
        }
    }

    private func replace(
        _ oldRows: Range<Int>, newRows: [RichRow], metrics newMetrics: [RichRowMetrics], itemCounts: [Int], keptRows: Int, movesFocus: Bool
    ) {
        rowIDs.replaceSubrange(oldRows, with: newRows.map(\.id))
        metrics.replaceSubrange(oldRows, with: newMetrics)
        let change = RichEditor.RowChange(oldRange: oldRows, newCount: newRows.count)
        let changedChrome = chrome.apply(change, blocks: model.editor.rows.lazy.map(\.block))
        // The focused text view may go away here. The responder holds the keyboard until the new text view takes it.
        if movesFocus, model.isFocused, list.view.window != nil, !responder.isFirstResponder { responder.becomeFirstResponder() }
        let oldItems = itemMap.replaceRows(oldRows, newItemCounts: itemCounts)
        let keptItems = itemCounts.prefix(keptRows).reduce(0, +)
        list.replaceItems(oldItems, newCount: itemCounts.reduce(0, +), keepingFirst: keptItems)
        if let changedChrome {
            // Renumbered items and new gaps outside the change. Off screen, only their heights become guesses again.
            list.reconfigureItems(changedChrome.flatMap(itemMap.items(forRow:)))
        } else {
            reconfigureVisibleItems()
        }
        // The focus path scrolls to the caret. A checkbox tap far from the caret must not scroll there.
        if movesFocus, model.isFocused { focusSelection() }
    }

    /// Reads every row again: a missed change or new link definitions.
    /// `rendersRawRows`: render the raw rows again too. After a missed change any raw row can be new.
    func reloadAll(rendersRawRows: Bool = true) {
        let count = model.rowCount
        rowIDs = (0..<count).map { model.row(at: $0).id }
        metrics = (0..<count).map { RichRowMetrics(block: model.row(at: $0).block) }
        shapes = (0..<count).map { RichRowShape(block: model.row(at: $0).block) }
        chrome = RichChromeIndex(blocks: model.editor.rows.lazy.map(\.block), numbers: model.orderedNumbers())
        if rendersRawRows {
            let raw = (0..<count).compactMap { Self.rawRow(model.row(at: $0)) }
            rawCache = RichRawRenderCache(raw: raw, rows: [:], definitions: raw.isEmpty ? "" : model.referenceDefinitionSource)
        }
        itemMap = RichItemMap(itemCounts: (0..<count).map(itemCount(ofRow:)))
        list.reloadAll()
        if model.isFocused { focusSelection() }
    }

    private func selectionDidChange() {
        if model.isFocused { focusSelection() }
        refreshVisibleSelection()
    }

    private static func rawRow(_ row: RichRow) -> RichRawRenderCache.RawRow? {
        if case .rawSource(let source) = row.block { RichRawRenderCache.RawRow(id: row.id, source: source) } else { nil }
    }

    // MARK: - Cells

    func reconfigureVisibleItems() {
        list.reconfigureItems(list.view.indexPathsForVisibleItems.map(\.item))
    }

    /// Atomic rows show whether the selection covers them, so their visible items are configured again.
    private func refreshVisibleSelection() {
        let atomic = list.view.indexPathsForVisibleItems.map(\.item).filter { item in
            let row = itemMap.row(forItem: item).row
            return row < metrics.count && (metrics[row] == .divider || metrics[row] == .raw)
        }
        list.reconfigureItems(atomic)
    }

    private func content(forItem item: Int) -> some View {
        let (row, piece) = itemMap.row(forItem: item)
        let entry = model.row(at: row)
        let rowChrome = chrome[row]
        let content: RichRowView.Content
        switch entry.block {
        case .thematicBreak:
            content = .divider
        case .rawSource(let source):
            if let pieces = rawCache.previewRows(for: entry.id), piece < pieces.count {
                content = .rawPiece(Self.piece(pieces, at: piece, gapBelow: rowChrome.gapBelow))
            } else {
                content = .rawSource(source)
            }
        default:
            content = .text(entry.block, id: entry.id, version: model.version)
        }
        let id = entry.id
        return RichRowView(
            content: content,
            chrome: rowChrome,
            isSelected: isAtomicSelected(row),
            theme: theme,
            strings: strings,
            baseURL: baseURL,
            host: self,
            onToggleCheckbox: { [weak self] in
                guard let self, let current = self.row(for: id) else { return }
                // Run after the button's own update ends. Inside it, the button animates the new checkbox state.
                Task { @MainActor in self.model.toggleCheckbox(inRow: current) }
            },
            onSelectAtomic: { [weak self] in
                guard let self, let current = self.row(for: id) else { return }
                selectAtomic(row: current)
            }
        )
        // Side padding sits in each row, so every cell spans the full width.
        .padding(.horizontal, Self.rowSideInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.markdownTheme, theme)
        .environment(\.markdownEditorStrings, strings)
        .environment(\.markdownImageLoading, imageLoading)
    }

    /// The last piece of a raw block takes the gap the editor chrome gives the row.
    private static func piece(_ pieces: [PreviewRow], at index: Int, gapBelow: MarkdownRowGap) -> PreviewRow {
        var row = pieces[index]
        if index == pieces.count - 1 { row.chrome.gapBelow = gapBelow }
        return row
    }

    private func isAtomicSelected(_ row: Int) -> Bool {
        let selection = model.selection
        guard !selection.isCaret, selection.blockIndexes.contains(row), metrics[row] == .divider || metrics[row] == .raw else {
            return false
        }
        let start = selection.start.blockIndex == row ? selection.start.offset : 0
        let end = selection.end.blockIndex == row ? selection.end.offset : 1
        return start == 0 && end == 1
    }
}

// MARK: - MarkdownRowListDataSource

extension RichRowAdapter: MarkdownRowListDataSource {
    var itemCount: Int { itemMap.itemCount }

    func configure(_ cell: MarkdownRowCell, forItem item: Int) {
        guard item < itemMap.itemCount, itemMap.row(forItem: item).row < metrics.count else { return }
        let content = content(forItem: item)
        cell.contentConfiguration = UIHostingConfiguration { content }
            .margins(.all, 0)
            .minSize(height: 0)
    }

    func estimatedHeight(ofItem item: Int, using estimator: MarkdownRowEstimator) -> CGFloat {
        let (row, piece) = itemMap.row(forItem: item)
        guard row < metrics.count else { return 1 }
        let rowChrome = chrome[row]
        let gap = estimator.gapHeight(rowChrome.gapBelow)
        let depth = rowChrome.decorations.count
        switch metrics[row] {
        case .text(let bytes, let headingLevel):
            return estimator.textHeight(units: bytes, headingLevel: headingLevel, depth: depth) + gap
        case .code(let lines, let hasLanguage):
            return estimator.codeHeight(lines: lines, hasLanguage: hasLanguage, isFirst: true, isLast: true) + gap
        case .divider:
            return estimator.dividerHeight() + gap
        case .raw:
            guard let pieces = rawCache.previewRows(for: rowIDs[row]), piece < pieces.count else {
                return estimator.textHeight(units: 1, headingLevel: nil, depth: depth) + gap
            }
            return estimator.height(of: Self.piece(pieces, at: piece, gapBelow: rowChrome.gapBelow))
        }
    }

    /// A raw image changes its height when the image loads.
    /// During a batch update the layout can still ask for an old item past the end, so rows are checked.
    func alwaysSizes(item: Int) -> Bool {
        let (row, piece) = itemMap.row(forItem: item)
        guard row < metrics.count, metrics[row] == .raw, let pieces = rawCache.previewRows(for: rowIDs[row]), piece < pieces.count,
              case .block(let block) = pieces[piece].content, case .image = block.kind else { return false }
        return true
    }
}

private extension MarkdownImageLoading {
    /// Tells the cases apart. `provided` holds a closure, so the enum is not `Equatable`.
    var caseIndex: Int {
        switch self {
        case .altTextOnly: 0
        case .remote: 1
        case .provided: 2
        }
    }
}
