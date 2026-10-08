import UIKit

/// A long list of rows in a collection view: the view, its layout and the item heights.
/// Items are plain indexes. The caller keeps the identity of its rows and tells the list what changed.
/// Each append adds a collection view section, but items are numbered across all sections.
/// Changes never animate. The list leaves `view.delegate`, the content insets and the keyboard dismiss mode to the host.
@MainActor
package final class MarkdownRowList: NSObject {
    package let view: MarkdownRowListView
    private let layout = MarkdownRowLayout()
    private weak var dataSource: (any MarkdownRowListDataSource)?
    private var registration: UICollectionView.CellRegistration<MarkdownRowCell, Int>?
    /// An item to show at the same place after the next layout pass, and its top relative to the top edge.
    private var pendingAnchor: (item: Int, distance: CGFloat)?
    private var themeVersion = 0
    /// True in `replaceItems` until its update block runs. The items configured then are in `itemsConfiguredEarly`.
    private var isBeforeUpdate = false
    private var itemsConfiguredEarly: [Int] = []

    /// Fonts and spacing of the estimates. A change makes every height a guess again.
    package var theme = MarkdownTheme.default {
        didSet {
            guard theme != oldValue else { return }
            themeVersion += 1
            heightInputsChanged()
        }
    }

    /// An item whose cell stays attached however far the list scrolls, for example the row with the keyboard focus.
    /// Indexes do not follow changes: set it again after items before it are inserted or deleted.
    package var pinnedItem: Int? {
        didSet {
            guard pinnedItem != oldValue else { return }
            layout.pinnedItem = pinnedItem
            layout.invalidateLayout()
        }
    }

    package init(dataSource: any MarkdownRowListDataSource) {
        view = MarkdownRowListView(frame: .zero, collectionViewLayout: layout)
        self.dataSource = dataSource
        super.init()
        registration = UICollectionView.CellRegistration { [weak self] cell, _, item in
            guard let self else { return }
            if isBeforeUpdate { itemsConfiguredEarly.append(item) }
            self.dataSource?.configure(cell, forItem: item)
        }
        view.backgroundColor = .clear
        view.allowsSelection = false
        // A cell whose content changes its size asks for a new size by itself.
        view.selfSizingInvalidation = .enabled
        view.dataSource = self
        view.onLayout = { [weak self] in self?.applyAnchor() }
        view.onTextSizeChange = { [weak self] in self?.heightInputsChanged() }
        layout.alwaysSizes = { [weak self] item in self?.dataSource?.alwaysSizes(item: item) ?? false }
        layout.onWidthChange = { [weak self] oldWidth, _ in self?.widthChanged(from: oldWidth) }
    }

    package var itemCount: Int { layout.heights.count }

    /// The item at the top edge of the visible area.
    package var topItem: Int {
        layout.heights.index(at: view.contentOffset.y + view.adjustedContentInset.top + 1)
    }

    // MARK: - Changes

    /// Reads every item again. Use it for a new document.
    package func reloadAll() {
        let count = dataSource?.itemCount ?? 0
        updateSizingKey()
        layout.heights = MarkdownRowHeights(heights: estimates(0..<count))
        layout.sectionStarts = [0]
        pendingAnchor = nil
        UIView.performWithoutAnimation {
            view.reloadData()
            layout.invalidateLayout()
        }
    }

    /// Adds `count` items at the end, in a new section. Items on screen do not move.
    package func appendItems(count: Int) {
        guard count > 0 else { return }
        let start = layout.heights.count
        // An empty list has no cell to keep.
        guard start > 0 else {
            reloadAll()
            return
        }
        let values = estimates(start..<(start + count))
        let section = layout.sectionStarts.count
        UIView.performWithoutAnimation {
            view.performBatchUpdates {
                layout.heights.append(contentsOf: values)
                layout.sectionStarts.append(start)
                // insertItems makes one update per item. For a large batch that blocks the main thread for many frames.
                view.insertSections(IndexSet(integer: section))
            }
        }
    }

    /// Replaces the items in `old` with `newCount` items, in one update without animation.
    /// The first `keepingFirst` items stay in their cells and are configured again, so a text view in them keeps the focus.
    /// Their measured height is a guess again. The other old items are deleted and the other new items inserted.
    package func replaceItems(_ old: Range<Int>, newCount: Int, keepingFirst: Int) {
        guard old.lowerBound >= 0, old.upperBound <= layout.heights.count, newCount >= 0 else {
            reloadAll()
            return
        }
        let section = layout.section(ofItem: old.lowerBound)
        let start = layout.sectionStarts[section]
        // Only appends add sections, so a range across sections is rare. Read every item again then.
        guard old.upperBound <= start + layout.itemCount(inSection: section) else {
            reloadAll()
            return
        }
        let kept = max(0, min(keepingFirst, old.count, newCount))
        let estimator = makeEstimator()
        let values = (0..<newCount).map { offset in
            let item = old.lowerBound + offset
            // A kept item starts at its old height, so it does not jump before it sizes itself.
            return offset < kept ? layout.heights.height(at: item) : estimate(item, estimator)
        }
        let path = { IndexPath(item: $0 - start, section: section) }
        let keptPaths = (old.lowerBound..<(old.lowerBound + kept)).map(path)
        let deleted = ((old.lowerBound + kept)..<old.upperBound).map(path)
        let inserted = ((old.lowerBound + kept)..<(old.lowerBound + newCount)).map(path)
        // The data source already has the new items. A layout pass that is due runs first in the batch update,
        // with the old index paths. A cell made then, for example a prefetched cell, gets the wrong item.
        isBeforeUpdate = true
        itemsConfiguredEarly = []
        UIView.performWithoutAnimation {
            view.performBatchUpdates {
                isBeforeUpdate = false
                layout.heights.replaceSubrange(old, with: values)
                for later in (section + 1)..<layout.sectionStarts.count {
                    layout.sectionStarts[later] += newCount - old.count
                }
                if !deleted.isEmpty { view.deleteItems(at: deleted) }
                if !inserted.isEmpty { view.insertItems(at: inserted) }
                if !keptPaths.isEmpty { view.reconfigureItems(at: keptPaths) }
            }
        }
        // A cell made early below `old` moved with the update. A reload gives it a new cell and a new size.
        // Items above `old` did not change, kept items are configured again above, and deleted items are gone.
        let moved = itemsConfiguredEarly.filter { $0 >= old.upperBound }.map { $0 + newCount - old.count }
        itemsConfiguredEarly = []
        guard !moved.isEmpty else { return }
        for item in moved {
            layout.heights.invalidate(item)
        }
        UIView.performWithoutAnimation {
            view.reloadItems(at: moved.map(indexPath))
        }
    }

    /// Configures the items again in their cells. Their measured heights are guesses again.
    package func reconfigureItems(_ items: some Sequence<Int>) {
        let valid = items.filter { $0 >= 0 && $0 < layout.heights.count }
        guard !valid.isEmpty else { return }
        for item in valid {
            layout.heights.invalidate(item)
        }
        UIView.performWithoutAnimation {
            view.reconfigureItems(at: valid.map(indexPath))
            // UIKit sizes a reconfigured cell once with its old content and marks it measured. A second pass
            // after the new content is in makes the cell size itself to it.
            view.layoutIfNeeded()
            for item in valid {
                invalidateHeight(ofItem: item)
            }
        }
    }

    /// The item's content changed its height, for example a text view got a new line.
    /// Only the layout is invalidated: the cell is not configured again, so its text view keeps the focus.
    package func invalidateHeight(ofItem item: Int) {
        guard item >= 0, item < layout.heights.count else { return }
        layout.heights.invalidate(item)
        let context = UICollectionViewLayoutInvalidationContext()
        context.invalidateItems(at: [indexPath(item)])
        layout.invalidateLayout(with: context)
        // Asks the cell for a new size in the next layout pass.
        cell(forItem: item)?.invalidateIntrinsicContentSize()
    }

    // MARK: - Geometry

    /// The item's frame in the list view, from the stored heights. No cell is needed.
    package func itemFrame(at item: Int) -> CGRect {
        CGRect(x: 0, y: layout.heights.offset(of: item), width: view.bounds.width, height: layout.heights.height(at: item))
    }

    /// The item at `point` in the list view, or nil above the first item and below the last.
    package func item(at point: CGPoint) -> Int? {
        guard layout.heights.count > 0, point.y >= 0, point.y < layout.heights.totalHeight else { return nil }
        return layout.heights.index(at: point.y)
    }

    /// The item that a collection view index path shows, for a delegate method.
    package func item(for indexPath: IndexPath) -> Int {
        layout.item(at: indexPath)
    }

    /// The item's cell while it is on screen or pinned, else nil.
    package func cell(forItem item: Int) -> MarkdownRowCell? {
        guard item >= 0, item < layout.heights.count else { return nil }
        return view.cellForItem(at: indexPath(item)) as? MarkdownRowCell
    }

    /// Scrolls the least distance that shows `rect` of the item, or the whole item when `rect` is nil.
    /// `rect` is in the item's coordinates, for example the caret. `completion` runs after the layout pass,
    /// so `cell(forItem:)` returns the cell.
    package func scrollToItem(_ item: Int, rect: CGRect?, completion: () -> Void) {
        guard item >= 0, item < layout.heights.count else {
            completion()
            return
        }
        // Cells near the target size themselves in the layout pass and can move it, so try again a few times.
        for _ in 0..<3 {
            let frame = itemFrame(at: item)
            let target = rect.map { $0.offsetBy(dx: frame.minX, dy: frame.minY) } ?? frame
            view.scrollRectToVisible(target, animated: false)
            view.layoutIfNeeded()
            if itemFrame(at: item) == frame { break }
        }
        completion()
    }

    // MARK: - Heights

    private func makeEstimator() -> MarkdownRowEstimator {
        MarkdownRowEstimator(width: view.bounds.width, traits: view.traitCollection, theme: theme)
    }

    private func estimate(_ item: Int, _ estimator: MarkdownRowEstimator) -> CGFloat {
        dataSource?.estimatedHeight(ofItem: item, using: estimator) ?? 0
    }

    private func estimates(_ items: Range<Int>) -> [CGFloat] {
        let estimator = makeEstimator()
        return items.map { estimate($0, estimator) }
    }

    private func updateSizingKey() {
        layout.sizingKey = MarkdownRowSizingKey(
            width: view.bounds.width,
            contentSizeCategory: view.traitCollection.preferredContentSizeCategory,
            legibilityWeight: view.traitCollection.legibilityWeight,
            themeVersion: themeVersion
        )
    }

    /// Every height is a guess again: estimate all items and keep the anchor item in place.
    private func resetHeights() {
        updateSizingKey()
        layout.heights = MarkdownRowHeights(heights: estimates(0..<layout.heights.count))
    }

    /// Called inside the layout's `prepare()`, with the heights of the old width.
    private func widthChanged(from oldWidth: CGFloat) {
        guard layout.heights.count > 0 else {
            updateSizingKey()
            return
        }
        let anchor = oldWidth > 0 ? currentAnchor() : nil
        resetHeights()
        if let anchor { pendingAnchor = anchor }
    }

    /// The text size, Bold Text or the theme changed.
    private func heightInputsChanged() {
        guard layout.heights.count > 0 else {
            updateSizingKey()
            return
        }
        pendingAnchor = currentAnchor()
        resetHeights()
        UIView.performWithoutAnimation {
            layout.invalidateLayout()
            view.reconfigureItems(at: view.indexPathsForVisibleItems)
        }
        view.setNeedsLayout()
    }

    // MARK: - Anchor

    /// The pinned item when there is one, else the top item, and its top relative to the top edge.
    private func currentAnchor() -> (item: Int, distance: CGFloat) {
        let item = pinnedItem.flatMap { $0 < layout.heights.count ? $0 : nil } ?? topItem
        let top = view.contentOffset.y + view.adjustedContentInset.top
        return (item, layout.heights.offset(of: item) - top)
    }

    private func applyAnchor() {
        guard let anchor = pendingAnchor, view.bounds.height > 0 else { return }
        pendingAnchor = nil
        guard anchor.item < layout.heights.count else { return }
        let inset = view.adjustedContentInset
        let maxOffset = max(layout.heights.totalHeight + inset.bottom - view.bounds.height, -inset.top)
        let target = min(max(layout.heights.offset(of: anchor.item) - anchor.distance - inset.top, -inset.top), maxOffset)
        if abs(view.contentOffset.y - target) > 0.5 { view.contentOffset.y = target }
    }

    private func indexPath(_ item: Int) -> IndexPath {
        layout.indexPath(ofItem: item)
    }
}

// MARK: - UICollectionViewDataSource

extension MarkdownRowList: UICollectionViewDataSource {
    package func numberOfSections(in collectionView: UICollectionView) -> Int {
        layout.sectionStarts.count
    }

    package func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        layout.itemCount(inSection: section)
    }

    package func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let registration else { return UICollectionViewCell() }
        return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: layout.item(at: indexPath))
    }
}
