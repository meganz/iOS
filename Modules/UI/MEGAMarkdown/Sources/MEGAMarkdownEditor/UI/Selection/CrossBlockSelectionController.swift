import MEGAMarkdown
import UIKit

/// Shows and changes a selection over rows with the system selection display: highlight, handles and edit menu.
/// The model holds the selection. This keeps its direction (anchor and head). One text row keeps its own selection.
@MainActor
final class CrossBlockSelectionController: NSObject {
    private(set) weak var adapter: RichRowAdapter?
    private let displayInput = SelectionDisplayInput()
    private var display: UITextSelectionDisplayInteraction?
    private var editMenu: UIEditMenuInteraction?
    private var watcher: SelectionDragWatcher?
    /// The selection over rows on screen, with its direction. nil while the model's selection is inside one text row.
    var selection: CrossBlockSelection?
    /// What the current touch does to the selection.
    var drag = SelectionDrag.idle
    /// Where and when the current touch started, in the list view.
    var touchStart: (point: CGPoint, time: CFTimeInterval)?
    /// The model version when the current touch started. A content change after it ends the drag.
    var touchVersion: Int?
    /// True when the current touch started on a handle or inside the highlight.
    var isTouchOnSelection = false
    var loupe: UITextLoupeSession?
    /// The finger of the current drag, in window coordinates. It stays still while the list scrolls under it.
    var lastFingerInWindow: CGPoint?
    var autoScroller: SelectionAutoScroller?
    /// The gap heights of atomic rows.
    var gapHeights = SelectionGapHeights()

    init(adapter: RichRowAdapter) {
        self.adapter = adapter
        super.init()
    }

    /// Installs the selection display on the list and the edit menu on the selection responder.
    func attach() {
        guard let adapter, display == nil else { return }
        let listView = adapter.list.view
        displayInput.geometry = self
        displayInput.hostView = listView
        let display = UITextSelectionDisplayInteraction(textInput: displayInput, delegate: self)
        listView.addInteraction(display)
        self.display = display
        // The menu shows the edit actions the selection responder can do, so it sits on that responder.
        let editMenu = UIEditMenuInteraction(delegate: self)
        adapter.responder.addInteraction(editMenu)
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
        let autoScroller = SelectionAutoScroller(scrollView: listView)
        autoScroller.onScroll = { [weak self] in self?.autoscrolled() }
        self.autoScroller = autoScroller
        adapter.selectionHandler = self
        adapter.onLayout = { [weak self] in self?.refreshDisplay() }
        modelDidChange()
    }

    /// Removes what `attach()` installed, so a new list view of the same adapter can attach its own.
    func detach() {
        guard let adapter else { return }
        if let display { adapter.list.view.removeInteraction(display) }
        if let editMenu { adapter.responder.removeInteraction(editMenu) }
        if let watcher { adapter.list.view.removeGestureRecognizer(watcher) }
        autoScroller?.stop()
        loupe?.invalidate()
        display = nil
        editMenu = nil
        watcher = nil
        autoScroller = nil
        loupe = nil
        // A new list view of the same adapter can attach before this one detaches. Its hooks stay.
        if adapter.selectionHandler === self {
            adapter.selectionHandler = nil
            adapter.onLayout = nil
        }
    }

    /// Mirrors the model after each change. A selection over rows shows the highlight and the handles,
    /// also after undo, redo and Select All. A selection in one row clears them.
    func modelDidChange() {
        guard let model = adapter?.model else { return }
        // A content change (⌘X, undo) can remove the rows the drag names. The model's selection wins.
        if drag != .idle, touchVersion != model.version { endDrag() }
        // During a drag the layer leads. The model gets the selection when the finger lifts.
        if case .dragging = drag { return }
        let range = model.selection
        guard showsLayer(range) else {
            clear()
            return
        }
        if selection?.range != range {
            selection = CrossBlockSelection(anchor: range.start, head: range.end)
        }
        refreshDisplay()
    }

    /// The layer draws a selection over rows, and a divider or raw block selected whole.
    /// A selection inside one text row stays with that row's text view.
    func showsLayer(_ range: RichSelection) -> Bool {
        guard range.isInOneBlock else { return true }
        guard !range.isCaret, let model = adapter?.model, range.start.blockIndex < model.rowCount else { return false }
        return model.row(at: range.start.blockIndex).block.plainText == nil
    }

    /// Select All from a row, the selection responder or the edit menu: the whole document, and the edit menu.
    func selectAll() {
        guard let model = adapter?.model else { return }
        model.setFocused(true)
        model.selectAll()
        presentEditMenu()
    }

    func clear() {
        guard selection != nil else { return }
        selection = nil
        editMenu?.dismissMenu()
        refreshDisplay()
    }

    // MARK: - Display

    /// Places the highlight and the handles again. Runs after every layout pass, so rows that scroll in get them.
    func refreshDisplay() {
        // While the adapter applies a change, the list and the model differ, and the selection may name old rows.
        // The adapter calls `modelDidChange()` when it is done.
        guard let display, let adapter, adapter.appliedVersion == adapter.model.version else { return }
        displayInput.span = selection?.range.span
        let isActive = selection != nil
        if display.isActivated != isActive { display.isActivated = isActive }
        guard isActive else { return }
        display.setNeedsSelectionUpdate()
        display.layoutManagedSubviews()
    }

    var isDisplayActive: Bool { display?.isActivated ?? false }
    var handleViews: [UIView] { display?.handleViews ?? [] }

    // MARK: - Edit menu

    func dismissEditMenu() {
        editMenu?.dismissMenu()
    }

    func presentEditMenu() {
        guard let editMenu, let menuView = editMenu.view, let listView = adapter?.list.view,
              let bounds = visibleSelectionBounds() else { return }
        let point = listView.convert(CGPoint(x: bounds.midX, y: bounds.minY), to: menuView)
        editMenu.presentEditMenu(with: UIEditMenuConfiguration(identifier: nil, sourcePoint: point))
    }

    /// The union of the highlight rects on screen, in the list view. Parts off screen do not count,
    /// so the menu points at the part of the selection the user sees.
    func visibleSelectionBounds() -> CGRect? {
        guard let range = selection?.range, let visible = adapter?.list.view.bounds else { return nil }
        return SelectionGeometry.visibleBounds(of: selectionRects(for: range).map(\.rect), in: visible)
    }
}

// MARK: - UITextSelectionDisplayInteractionDelegate

extension CrossBlockSelectionController: @MainActor UITextSelectionDisplayInteractionDelegate {}

// MARK: - UIEditMenuInteractionDelegate

extension CrossBlockSelectionController: @MainActor UIEditMenuInteractionDelegate {
    /// The menu keeps clear of this rect, so it covers neither the selection nor its handles.
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, targetRectFor configuration: UIEditMenuConfiguration) -> CGRect {
        guard let view = interaction.view, let listView = adapter?.list.view,
              let bounds = visibleSelectionBounds()?.insetBy(dx: 0, dy: -SelectionGeometry.menuMargin) else { return .null }
        return listView.convert(bounds, to: view)
    }
}
