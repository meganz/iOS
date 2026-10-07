import UIKit

/// A vertical list layout on `MarkdownRowHeights`. Attributes are made on request for the asked rect only,
/// so a self-sizing pass never walks all items.
package final class MarkdownRowLayout: UICollectionViewLayout {
    package var heights = MarkdownRowHeights()
    /// The first item of each section. Items are numbered across all sections, so `heights` stays one flat list.
    /// A new section is cheap to insert: one update for all its items.
    package var sectionStarts = [0]
    /// Measured heights are valid only under this key. Change it together with `heights.resetMeasured()`.
    package var sizingKey = MarkdownRowSizingKey()
    /// Items that size their cell every time they show, for example a row with an image that loads later.
    package var alwaysSizes: ((Int) -> Bool)?
    /// An item whose attributes are returned for every rect, so its cell stays attached when it is far off screen.
    package var pinnedItem: Int?
    /// Called in `prepare()` when the width changes, before any attributes for the new width are made.
    package var onWidthChange: ((_ oldWidth: CGFloat, _ newWidth: CGFloat) -> Void)?
    package private(set) var width: CGFloat = 0

    override package class var layoutAttributesClass: AnyClass {
        MarkdownRowLayoutAttributes.self
    }

    override package var collectionViewContentSize: CGSize {
        CGSize(width: width, height: heights.totalHeight)
    }

    override package func prepare() {
        super.prepare()
        guard let collectionView else { return }
        let newWidth = collectionView.bounds.width
        guard newWidth != width else { return }
        let oldWidth = width
        width = newWidth
        onWidthChange?(oldWidth, newWidth)
    }

    override package func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard heights.count > 0 else { return [] }
        var index = heights.index(at: max(rect.minY, 0))
        var y = heights.offset(of: index)
        var result: [UICollectionViewLayoutAttributes] = []
        var hasPinned = false
        // `index(at:)` clamps to the last item, so a rect below the content must not return it.
        if rect.minY >= heights.totalHeight { index = heights.count }
        while index < heights.count && y < rect.maxY {
            let height = heights.height(at: index)
            result.append(attributes(index, y: y, height: height))
            hasPinned = hasPinned || index == pinnedItem
            y += height
            index += 1
        }
        if let pinnedItem, !hasPinned, pinnedItem < heights.count {
            result.append(attributes(pinnedItem, y: heights.offset(of: pinnedItem), height: heights.height(at: pinnedItem)))
        }
        return result
    }

    override package func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.section < sectionStarts.count else { return nil }
        let index = item(at: indexPath)
        guard index < heights.count else { return nil }
        return attributes(index, y: heights.offset(of: index), height: heights.height(at: index))
    }

    override package func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        newBounds.width != width
    }

    // MARK: - Self-sizing

    override package func shouldInvalidateLayout(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
    ) -> Bool {
        let index = item(at: originalAttributes.indexPath)
        guard abs(preferredAttributes.size.height - originalAttributes.size.height) >= 0.5 else {
            // The cell sized itself to the height it has. It is measured, so it is not sized again.
            if index < heights.count, !heights.isMeasured(index) { heights.set(index, height: heights.height(at: index)) }
            return false
        }
        return true
    }

    override package func invalidationContext(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutInvalidationContext {
        let context = UICollectionViewLayoutInvalidationContext()
        let index = item(at: originalAttributes.indexPath)
        guard index < heights.count else { return context }
        let delta = preferredAttributes.size.height - heights.height(at: index)
        heights.set(index, height: preferredAttributes.size.height)
        context.contentSizeAdjustment = CGSize(width: 0, height: delta)
        // An item above the top edge grew or shrank. Move the offset too, so the content on screen stays still.
        if let collectionView, originalAttributes.frame.minY < collectionView.contentOffset.y + collectionView.adjustedContentInset.top - 0.5 {
            context.contentOffsetAdjustment = CGPoint(x: 0, y: delta)
        }
        return context
    }

    // MARK: - Sections

    package func item(at indexPath: IndexPath) -> Int {
        sectionStarts[indexPath.section] + indexPath.item
    }

    package func indexPath(ofItem item: Int) -> IndexPath {
        let section = self.section(ofItem: item)
        return IndexPath(item: item - sectionStarts[section], section: section)
    }

    /// The last section that starts at or before `item`, so an empty section never holds it.
    package func section(ofItem item: Int) -> Int {
        var low = 0
        var high = sectionStarts.count - 1
        while low < high {
            let middle = (low + high + 1) / 2
            if sectionStarts[middle] <= item { low = middle } else { high = middle - 1 }
        }
        return low
    }

    package func itemCount(inSection section: Int) -> Int {
        let end = section + 1 < sectionStarts.count ? sectionStarts[section + 1] : heights.count
        return end - sectionStarts[section]
    }

    // MARK: - Attributes

    private func attributes(_ index: Int, y: CGFloat, height: CGFloat) -> MarkdownRowLayoutAttributes {
        let attributes = MarkdownRowLayoutAttributes(forCellWith: indexPath(ofItem: index))
        attributes.frame = CGRect(x: 0, y: y, width: width, height: height)
        attributes.isMeasured = heights.isMeasured(index) && !(alwaysSizes?(index) ?? false)
        attributes.sizingKey = sizingKey
        return attributes
    }
}
