import UIKit

/// A selection of whole blocks in the preview: `anchorRow` stays, `headRow` follows the finger. Each is any row of its block.
struct PreviewSelection: Equatable {
    var anchorRow: Int
    var headRow: Int
}

/// Selects whole blocks of the preview with a long press and the handles. Copy writes their plain text.
/// The preview has no model, so this holds the selection. It draws with the system selection display, like the editor.
@MainActor
final class PreviewSelectionController: NSObject {
    private(set) weak var list: MarkdownRowList?
    /// The rows of the preview. It changes when the preview shows a new text.
    private let rows: () -> PreviewRowStore
    let displayInput = SelectionDisplayInput()
    private(set) var display: UITextSelectionDisplayInteraction?
    let responder = PreviewSelectionResponder()
    private var editMenu: UIEditMenuInteraction?
    private var watcher: SelectionDragWatcher?
    private(set) var longPress: UILongPressGestureRecognizer?
    var autoScroller: SelectionAutoScroller?
    var loupe: UITextLoupeSession?
    /// Called when a selection starts, so a restore of the reading place stops moving the list.
    var onBegin: (() -> Void)?

    var selection: PreviewSelection? {
        didSet { if selection != oldValue { refreshDisplay() } }
    }
    /// What the current touch does: nil, a handle drag, or a drag after a long press. `offset` goes from the finger to
    /// the grabbed caret.
    var drag: (grabsStart: Bool?, offset: CGPoint, isDragging: Bool)?
    var touchStart: (point: CGPoint, time: CFTimeInterval)?
    var isTouchOnSelection = false
    var lastFingerInWindow: CGPoint?
    var gapHeights = SelectionGapHeights()
    /// Where Copy writes. Tests pass their own, so they never read the system pasteboard.
    var pasteboard = UIPasteboard.general
    private var selectedRowsCache: SelectedRowsCache?

    init(list: MarkdownRowList, rows: @escaping () -> PreviewRowStore) {
        self.list = list
        self.rows = rows
        super.init()
    }

    var store: PreviewRowStore { rows() }

    func attach() {
        guard let list, display == nil else { return }
        let listView = list.view
        displayInput.geometry = self
        displayInput.hostView = listView
        let display = UITextSelectionDisplayInteraction(textInput: displayInput, delegate: self)
        listView.addInteraction(display)
        self.display = display
        listView.addSubview(responder)
        responder.controller = self
        // The menu shows the edit actions the responder can do: Copy and Select All.
        let editMenu = UIEditMenuInteraction(delegate: self)
        responder.addInteraction(editMenu)
        self.editMenu = editMenu
        let watcher = SelectionDragWatcher(target: nil, action: nil)
        watcher.onBegan = { [weak self] point, others in self?.touchBegan(at: point, others: others) }
        watcher.onMoved = { [weak self] point, inWindow, others in
            self?.touchMoved(to: point, inWindow: inWindow, others: others) ?? false
        }
        watcher.onEnded = { [weak self] point, listPanBegan, cancelled in
            self?.touchEnded(at: point, listPanBegan: listPanBegan, cancelled: cancelled)
        }
        listView.addGestureRecognizer(watcher)
        self.watcher = watcher
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        longPress.delegate = self
        listView.addGestureRecognizer(longPress)
        self.longPress = longPress
        let autoScroller = SelectionAutoScroller(scrollView: listView)
        autoScroller.onScroll = { [weak self] in self?.autoscrolled() }
        self.autoScroller = autoScroller
    }

    func detach() {
        guard let list else { return }
        clear()
        if let display { list.view.removeInteraction(display) }
        if let watcher { list.view.removeGestureRecognizer(watcher) }
        if let longPress { list.view.removeGestureRecognizer(longPress) }
        if let editMenu { responder.removeInteraction(editMenu) }
        responder.removeFromSuperview()
        autoScroller?.stop()
        display = nil
        watcher = nil
        longPress = nil
        editMenu = nil
        autoScroller = nil
    }

    // MARK: - Selection

    /// The rows of the selected blocks, first to last. Each layout pass reads them, and the block search walks
    /// every piece of a big block. So the result is kept until the selection or the rows change.
    var selectedRows: ClosedRange<Int>? {
        let store = store
        guard let selection, selection.anchorRow < store.count, selection.headRow < store.count else { return nil }
        if let cache = selectedRowsCache, cache.selection == selection, cache.store === store, cache.rowCount == store.count {
            return cache.rows
        }
        let anchor = PreviewBlocks.rows(ofBlockAt: selection.anchorRow, in: store)
        let head = PreviewBlocks.rows(ofBlockAt: selection.headRow, in: store)
        let rows = min(anchor.lowerBound, head.lowerBound)...max(anchor.upperBound, head.upperBound)
        selectedRowsCache = SelectedRowsCache(selection: selection, store: store, rowCount: store.count, rows: rows)
        return rows
    }

    func selectAll() {
        guard store.count > 0 else { return }
        onBegin?()
        selection = PreviewSelection(anchorRow: 0, headRow: store.count - 1)
        presentEditMenu()
    }

    func clear() {
        guard selection != nil else { return }
        selection = nil
        drag = nil
        autoScroller?.stop()
        loupe?.invalidate()
        loupe = nil
        editMenu?.dismissMenu()
        if responder.isFirstResponder { responder.resignFirstResponder() }
    }

    /// The plain text of the selected blocks.
    func selectedText() -> String? {
        selectedRows.map { PreviewBlocks.plainText(of: $0, in: store) }
    }

    /// Writes the selected blocks as plain text. No Markdown type: the preview shows formatted text, not source.
    func copySelection() {
        guard let text = selectedText() else { return }
        pasteboard.string = text
    }

    // MARK: - Display

    /// Runs after every layout pass, so rows that scroll in get their highlight.
    func refreshDisplay() {
        guard let display else { return }
        let rows = selectedRows
        displayInput.span = rows.map { SelectionSpan(SelectionPoint(row: $0.lowerBound, offset: 0), SelectionPoint(row: $0.upperBound, offset: 1)) }
        let isActive = rows != nil
        if display.isActivated != isActive { display.isActivated = isActive }
        guard isActive else { return }
        display.setNeedsSelectionUpdate()
        display.layoutManagedSubviews()
    }

    var isDisplayActive: Bool { display?.isActivated ?? false }

    func presentEditMenu() {
        guard let editMenu, let listView = list?.view, let bounds = visibleSelectionBounds() else { return }
        if !responder.isFirstResponder { responder.becomeFirstResponder() }
        let point = listView.convert(CGPoint(x: bounds.midX, y: bounds.minY), to: responder)
        editMenu.presentEditMenu(with: UIEditMenuConfiguration(identifier: nil, sourcePoint: point))
    }

    func dismissEditMenu() {
        editMenu?.dismissMenu()
    }

    /// The union of the highlight rects on screen, in the list view. Parts off screen do not count,
    /// so the menu points at the part of the selection the user sees.
    func visibleSelectionBounds() -> CGRect? {
        guard let span = displayInput.span, let visible = listView?.bounds else { return nil }
        // Zero-width rects stand for ends off screen, so they do not count.
        let rects = selectionRects(for: span).map(\.rect).filter { $0.width > 0 }
        return SelectionGeometry.visibleBounds(of: rects, in: visible)
    }

    var listView: MarkdownRowListView? { list?.view }
}

/// The selected rows for one selection over one state of the rows. Rows are only appended, so the count names the state.
private struct SelectedRowsCache {
    let selection: PreviewSelection
    weak var store: PreviewRowStore?
    let rowCount: Int
    let rows: ClosedRange<Int>
}

// MARK: - UITextSelectionDisplayInteractionDelegate

extension PreviewSelectionController: @MainActor UITextSelectionDisplayInteractionDelegate {}

// MARK: - UIEditMenuInteractionDelegate

extension PreviewSelectionController: @MainActor UIEditMenuInteractionDelegate {
    /// The menu keeps clear of the selection and its handles.
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, targetRectFor configuration: UIEditMenuConfiguration) -> CGRect {
        guard let view = interaction.view, let listView,
              let bounds = visibleSelectionBounds()?.insetBy(dx: 0, dy: -SelectionGeometry.menuMargin) else {
            return .null
        }
        return listView.convert(bounds, to: view)
    }
}
