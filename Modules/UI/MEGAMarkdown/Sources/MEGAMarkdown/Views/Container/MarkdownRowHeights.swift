import CoreGraphics

/// Item heights of a row list in a Fenwick tree (a prefix-sum tree), plus a "measured" flag per item.
/// The offset of an item and the item at a y are O(log n). No per-item layout attributes are stored.
package struct MarkdownRowHeights {
    /// Plain heights, so one height is O(1) and a middle replace can rebuild the tree in one pass.
    private var heights: [CGFloat]
    /// `tree[i]` holds the sum of heights in `(i - lowBit(i), i]`, one-based. `tree[0]` is unused.
    private var tree: [CGFloat]
    /// True for an item whose cell sized itself. An estimate must not replace that height.
    private var measured: [Bool]
    /// The highest power of two that is not above `count`, for the top-down search in `index(at:)`.
    private var topBit: Int

    package init(heights: [CGFloat] = []) {
        self.heights = heights
        tree = Self.tree(from: heights)
        measured = Array(repeating: false, count: heights.count)
        topBit = Self.topBit(for: heights.count)
    }

    package var count: Int { heights.count }

    package var totalHeight: CGFloat { offset(of: count) }

    /// Sum of the heights of the items before `index`.
    package func offset(of index: Int) -> CGFloat {
        var position = min(max(index, 0), count)
        var sum: CGFloat = 0
        while position > 0 {
            sum += tree[position]
            position -= position & -position
        }
        return sum
    }

    package func height(at index: Int) -> CGFloat {
        heights.indices.contains(index) ? heights[index] : 0
    }

    package func isMeasured(_ index: Int) -> Bool {
        measured.indices.contains(index) && measured[index]
    }

    /// The item that contains `y`. Clamped to the first and the last item.
    package func index(at y: CGFloat) -> Int {
        guard count > 0, y > 0 else { return 0 }
        var position = 0
        var remaining = y
        var step = topBit
        while step > 0 {
            let next = position + step
            if next <= count && tree[next] <= remaining {
                position = next
                remaining -= tree[next]
            }
            step >>= 1
        }
        return min(position, count - 1)
    }

    // MARK: - Changes

    /// Adds items at the end. O(k log n) for k new items.
    package mutating func append(contentsOf newHeights: some Collection<CGFloat>) {
        tree.reserveCapacity(count + newHeights.count + 1)
        for height in newHeights {
            heights.append(height)
            measured.append(false)
            // The new node covers `(i - lowBit(i), i]`: the new height plus the items before it in that range.
            let position = heights.count
            let start = position - (position & -position)
            tree.append(height + offset(of: position - 1) - offset(of: start))
        }
        topBit = Self.topBit(for: count)
    }

    /// Replaces the items in `range` with new unmeasured items. The same number of items, or a range that reaches
    /// the end, is O(k log n). Any other range rebuilds the tree after `range.lowerBound` in O(n).
    package mutating func replaceSubrange(_ range: Range<Int>, with newHeights: some Collection<CGFloat>) {
        guard range.lowerBound >= 0, range.upperBound <= count else { return }
        let start = range.lowerBound
        if newHeights.count == range.count {
            for (index, height) in zip(range, newHeights) {
                set(index, height: height)
                measured[index] = false
            }
            return
        }
        // Tree nodes up to `i` only cover items up to `i`, so the nodes up to `start` stay valid.
        tree.removeSubrange((start + 1)...)
        if range.upperBound == count {
            heights.removeSubrange(range)
            measured.removeSubrange(range)
            append(contentsOf: newHeights)
            return
        }
        heights.replaceSubrange(range, with: newHeights)
        measured.replaceSubrange(range, with: repeatElement(false, count: newHeights.count))
        tree.append(contentsOf: heights[start...])
        let count = heights.count
        // The kept nodes that reach past `start` add into the new nodes: `start`, then each lower bit removed.
        var index = start
        while index > 0 {
            let parent = index + (index & -index)
            if parent <= count { tree[parent] += tree[index] }
            index -= index & -index
        }
        // The usual linear build for the new nodes.
        for index in stride(from: start + 1, through: count, by: 1) {
            let parent = index + (index & -index)
            if parent <= count { tree[parent] += tree[index] }
        }
        topBit = Self.topBit(for: count)
    }

    /// A height from a cell that sized itself. It marks the item measured. O(log n).
    package mutating func set(_ index: Int, height: CGFloat) {
        guard heights.indices.contains(index) else { return }
        let delta = height - heights[index]
        heights[index] = height
        measured[index] = true
        guard delta != 0 else { return }
        var position = index + 1
        while position <= count {
            tree[position] += delta
            position += position & -position
        }
    }

    /// The item's height is a guess again: its cell must size itself the next time it shows.
    package mutating func invalidate(_ index: Int) {
        guard measured.indices.contains(index) else { return }
        measured[index] = false
    }

    /// A new width, text size or theme: every height is a guess again.
    package mutating func resetMeasured() {
        measured = Array(repeating: false, count: count)
    }

    // MARK: - Tree

    private static func tree(from heights: [CGFloat]) -> [CGFloat] {
        var tree = [0] + heights
        for index in stride(from: 1, through: heights.count, by: 1) {
            let parent = index + (index & -index)
            if parent <= heights.count { tree[parent] += tree[index] }
        }
        return tree
    }

    private static func topBit(for count: Int) -> Int {
        guard count > 0 else { return 0 }
        return 1 << (Int.bitWidth - 1 - count.leadingZeroBitCount)
    }
}
