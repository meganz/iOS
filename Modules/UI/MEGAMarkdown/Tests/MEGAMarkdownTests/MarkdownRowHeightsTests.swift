import CoreGraphics
@testable import MEGAMarkdown
import Testing

/// The item height tree and its "measured" flags. Every height is a multiple of 0.5, so all sums are exact.
struct MarkdownRowHeightsTests {
    private static func sample(_ count: Int, seed: Int = 7) -> [CGFloat] {
        (0..<count).map { CGFloat(10 + ($0 * seed) % 50) + ($0 % 3 == 0 ? 0.5 : 0) }
    }

    /// Offsets, heights and the lookup match plain prefix sums for every item.
    private static func expectMatches(_ tree: MarkdownRowHeights, _ plain: [CGFloat], sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(tree.count == plain.count, sourceLocation: sourceLocation)
        var sum: CGFloat = 0
        for index in plain.indices {
            #expect(tree.offset(of: index) == sum, "offset \(index)", sourceLocation: sourceLocation)
            #expect(tree.height(at: index) == plain[index], "height \(index)", sourceLocation: sourceLocation)
            // The start of the item and a point inside it.
            #expect(tree.index(at: sum) == index, "start \(index)", sourceLocation: sourceLocation)
            #expect(tree.index(at: sum + plain[index] / 2) == index, "inside \(index)", sourceLocation: sourceLocation)
            sum += plain[index]
        }
        #expect(tree.totalHeight == sum, sourceLocation: sourceLocation)
        #expect(tree.offset(of: plain.count) == sum, sourceLocation: sourceLocation)
    }

    @Test func offsetsAndLookupMatchPlainSums() {
        var plain = Self.sample(1_000)
        var tree = MarkdownRowHeights(heights: plain)
        for (index, height) in [(0, 99.0), (500, 1.0), (999, 300.0), (123, 44.5)] {
            plain[index] = height
            tree.set(index, height: height)
        }
        Self.expectMatches(tree, plain)
        #expect(tree.index(at: -5) == 0)
        #expect(tree.index(at: tree.totalHeight + 100) == 999)
    }

    @Test func emptyTree() {
        var tree = MarkdownRowHeights()
        #expect(tree.count == 0)
        #expect(tree.totalHeight == 0)
        #expect(tree.index(at: 10) == 0)
        tree.append(contentsOf: [20, 30])
        Self.expectMatches(tree, [20, 30])
    }

    /// Appends in several steps give the same tree as one build, for counts across powers of two.
    @Test func appendMatchesOneBuild() {
        let plain = Self.sample(1_100)
        var tree = MarkdownRowHeights()
        var start = 0
        for size in [1, 2, 5, 120, 128, 256, 300, 288] {
            tree.append(contentsOf: plain[start..<(start + size)])
            start += size
            Self.expectMatches(tree, Array(plain[..<start]))
        }
        #expect(start == plain.count)
    }

    @Test(arguments: [(400, 600, 50), (0, 1, 3), (0, 1_000, 10), (999, 999, 4), (10, 900, 0), (512, 513, 1), (10, 20, 10), (7, 9, 1)])
    func replaceInTheMiddle(lower: Int, upper: Int, newCount: Int) {
        var plain = Self.sample(1_000)
        var tree = MarkdownRowHeights(heights: plain)
        let replacement = Self.sample(newCount, seed: 13).map { $0 + 1 }
        plain.replaceSubrange(lower..<upper, with: replacement)
        tree.replaceSubrange(lower..<upper, with: replacement)
        Self.expectMatches(tree, plain)
    }

    @Test(arguments: [(900, 0), (900, 250), (1_000, 7), (0, 3), (998, 1)])
    func replaceAtTheEnd(lower: Int, newCount: Int) {
        var plain = Self.sample(1_000)
        var tree = MarkdownRowHeights(heights: plain)
        let replacement = Self.sample(newCount, seed: 11).map { $0 + 2 }
        plain.replaceSubrange(lower..<1_000, with: replacement)
        tree.replaceSubrange(lower..<1_000, with: replacement)
        Self.expectMatches(tree, plain)
    }

    /// Measured flags stay on appends. A replace clears them for the new items only, and keeps them elsewhere.
    @Test func measuredFlagsFollowTheItems() {
        var tree = MarkdownRowHeights(heights: Self.sample(10))
        for index in [1, 4, 5, 8] {
            tree.set(index, height: 40)
        }
        tree.append(contentsOf: [5, 6, 7])
        #expect((0..<13).filter(tree.isMeasured) == [1, 4, 5, 8])

        // Items 4 and 5 are replaced by three items. Item 8 moves to 9.
        tree.replaceSubrange(4..<6, with: [1, 2, 3])
        #expect((0..<14).filter(tree.isMeasured) == [1, 9])

        // A replace at the end clears only the new items.
        tree.set(12, height: 9)
        tree.replaceSubrange(11..<14, with: [4])
        #expect((0..<12).filter(tree.isMeasured) == [1, 9])

        tree.invalidate(9)
        #expect((0..<12).filter(tree.isMeasured) == [1])
        tree.resetMeasured()
        #expect((0..<12).filter(tree.isMeasured).isEmpty)
    }

    /// A self-size to the height the item already has still marks it measured.
    @Test func setToTheSameHeightMarksMeasured() {
        var tree = MarkdownRowHeights(heights: [10, 20, 30])
        tree.set(1, height: 20)
        #expect(tree.isMeasured(1))
        Self.expectMatches(tree, [10, 20, 30])
    }

    @Test func outOfRangeChangesDoNothing() {
        var tree = MarkdownRowHeights(heights: [10, 20])
        tree.set(5, height: 1)
        tree.set(-1, height: 1)
        tree.invalidate(7)
        tree.replaceSubrange(1..<4, with: [1])
        Self.expectMatches(tree, [10, 20])
        #expect(!tree.isMeasured(5))
    }
}
