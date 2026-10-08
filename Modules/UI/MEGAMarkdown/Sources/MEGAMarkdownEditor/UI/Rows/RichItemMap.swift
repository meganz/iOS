/// Maps model rows to list items and back. Most rows are one item. A raw block can be several items,
/// one per preview row, so a large table is built a page at a time.
///
/// Only the rows with more than one item are stored, in row order, with the extra items before each.
/// A lookup is a binary search over them: O(log k) for k split rows. An update shifts the split rows after it: O(k).
struct RichItemMap: Equatable, Sendable {
    private struct Split: Equatable, Sendable {
        var row: Int
        var count: Int
        /// Extra items (count - 1) of the split rows before this one.
        var extraBefore: Int
    }

    private(set) var rowCount: Int
    private var splits: [Split] = []

    /// `itemCounts[row]` is the item count of each row. A count under 1 counts as 1.
    init(itemCounts: [Int]) {
        rowCount = itemCounts.count
        var extra = 0
        for (row, count) in itemCounts.enumerated() where count > 1 {
            splits.append(Split(row: row, count: count, extraBefore: extra))
            extra += count - 1
        }
    }

    var itemCount: Int {
        rowCount + extraItems
    }

    private var extraItems: Int {
        splits.last.map { $0.extraBefore + $0.count - 1 } ?? 0
    }

    /// The items of `row`.
    func items(forRow row: Int) -> Range<Int> {
        let index = firstSplit { $0.row >= row }
        let extraBefore = index < splits.count ? splits[index].extraBefore : extraItems
        let count = index < splits.count && splits[index].row == row ? splits[index].count : 1
        let first = row + extraBefore
        return first..<(first + count)
    }

    /// The row that shows `item`, and which of the row's items it is.
    func row(forItem item: Int) -> (row: Int, piece: Int) {
        // The first split row whose items end after `item`. Rows before it are one item each.
        let index = firstSplit { $0.row + $0.extraBefore + $0.count > item }
        if index < splits.count {
            let split = splits[index]
            let first = split.row + split.extraBefore
            if item >= first { return (split.row, item - first) }
            return (item - split.extraBefore, 0)
        }
        return (item - extraItems, 0)
    }

    /// Rows `oldRows` were replaced by rows with `newItemCounts`. Returns the items the old rows had.
    @discardableResult
    mutating func replaceRows(_ oldRows: Range<Int>, newItemCounts: [Int]) -> Range<Int> {
        let oldItems = items(forRow: oldRows.lowerBound).lowerBound..<(oldRows.isEmpty
            ? items(forRow: oldRows.lowerBound).lowerBound
            : items(forRow: oldRows.upperBound - 1).upperBound)
        let lower = firstSplit { $0.row >= oldRows.lowerBound }
        let upper = firstSplit { $0.row >= oldRows.upperBound }
        var extra = lower < splits.count ? splits[lower].extraBefore : extraItems
        let removedExtra = splits[lower..<upper].reduce(0) { $0 + $1.count - 1 }
        var inserted: [Split] = []
        for (offset, count) in newItemCounts.enumerated() where count > 1 {
            inserted.append(Split(row: oldRows.lowerBound + offset, count: count, extraBefore: extra))
            extra += count - 1
        }
        let addedExtra = extra - (lower < splits.count ? splits[lower].extraBefore : extraItems)
        let rowShift = newItemCounts.count - oldRows.count
        for index in upper..<splits.count {
            splits[index].row += rowShift
            splits[index].extraBefore += addedExtra - removedExtra
        }
        splits.replaceSubrange(lower..<upper, with: inserted)
        rowCount += rowShift
        return oldItems
    }

    /// The index of the first split where `isAfter` is true. `isAfter` must be false, then true, in split order.
    private func firstSplit(where isAfter: (Split) -> Bool) -> Int {
        var low = 0
        var high = splits.count
        while low < high {
            let middle = (low + high) / 2
            if isAfter(splits[middle]) { high = middle } else { low = middle + 1 }
        }
        return low
    }
}
