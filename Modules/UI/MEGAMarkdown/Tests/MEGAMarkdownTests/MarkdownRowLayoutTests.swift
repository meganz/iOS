@testable import MEGAMarkdown
import Testing
import UIKit

/// The row layout and the row cell, without a window.
@MainActor
struct MarkdownRowLayoutTests {
    private static func layout(count: Int, height: CGFloat = 44) -> MarkdownRowLayout {
        let layout = MarkdownRowLayout()
        layout.heights = MarkdownRowHeights(heights: Array(repeating: height, count: count))
        return layout
    }

    private static func items(_ attributes: [UICollectionViewLayoutAttributes]?) -> [Int] {
        (attributes ?? []).map(\.indexPath.item)
    }

    @Test func attributesOnlyForTheRect() throws {
        let layout = Self.layout(count: 1_000)
        let attributes = try #require(layout.layoutAttributesForElements(in: CGRect(x: 0, y: 440, width: 300, height: 100)))
        #expect(Self.items(attributes) == [10, 11, 12])
        #expect(attributes.map(\.frame.minY) == [440, 484, 528])
        #expect(attributes.allSatisfy { $0 is MarkdownRowLayoutAttributes && $0.frame.height == 44 })
        #expect(Self.items(layout.layoutAttributesForElements(in: CGRect(x: 0, y: 50_000, width: 300, height: 100))).isEmpty)
        #expect(layout.layoutAttributesForItem(at: IndexPath(item: 1_000, section: 0)) == nil)
    }

    @Test func pinnedItemIsAlwaysInTheAttributes() {
        let layout = Self.layout(count: 1_000)
        layout.pinnedItem = 900
        let rect = CGRect(x: 0, y: 0, width: 300, height: 100)
        #expect(Self.items(layout.layoutAttributesForElements(in: rect)) == [0, 1, 2, 900])
        layout.pinnedItem = 1
        #expect(Self.items(layout.layoutAttributesForElements(in: rect)) == [0, 1, 2])
        layout.pinnedItem = 5_000
        #expect(Self.items(layout.layoutAttributesForElements(in: rect)) == [0, 1, 2])
    }

    @Test func attributesCarryTheMeasuredFlagAndTheKey() throws {
        let layout = Self.layout(count: 10)
        layout.sizingKey = MarkdownRowSizingKey(width: 320, contentSizeCategory: .large, legibilityWeight: .regular, themeVersion: 3)
        layout.heights.set(2, height: 50)
        layout.heights.set(3, height: 60)
        layout.alwaysSizes = { $0 == 3 }
        let attributes = try #require(layout.layoutAttributesForElements(in: CGRect(x: 0, y: 0, width: 320, height: 500)))
            .compactMap { $0 as? MarkdownRowLayoutAttributes }
        #expect(attributes.count == 10)
        #expect(attributes.filter(\.isMeasured).map(\.indexPath.item) == [2])
        #expect(attributes.allSatisfy { $0.sizingKey == layout.sizingKey })
    }

    @Test func copyAndEqualityIncludeTheExtras() throws {
        let attributes = MarkdownRowLayoutAttributes(forCellWith: IndexPath(item: 4, section: 0))
        attributes.frame = CGRect(x: 0, y: 10, width: 300, height: 44)
        attributes.isMeasured = true
        attributes.sizingKey.themeVersion = 2
        let copy = try #require(attributes.copy() as? MarkdownRowLayoutAttributes)
        #expect(copy.isMeasured && copy.sizingKey.themeVersion == 2)
        #expect(copy.isEqual(attributes))
        copy.isMeasured = false
        #expect(!copy.isEqual(attributes))
        copy.isMeasured = true
        copy.sizingKey.themeVersion = 3
        #expect(!copy.isEqual(attributes))
    }

    /// UIKit asks for a new layout only for a change of 0.5 pt or more. An item that already had its real height
    /// must still count as measured, so it is not sized again.
    @Test func sameHeightSelfSizeMarksTheItemMeasured() {
        let layout = Self.layout(count: 10)
        let original = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: 4, section: 0))
        original.frame = CGRect(x: 0, y: 4 * 44, width: 390, height: 44)
        for (height, expected) in [(44.4, false), (43.6, false), (44.5, true), (43.5, true), (120, true), (10, true)] {
            let preferred = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: 4, section: 0))
            preferred.frame = CGRect(x: 0, y: 4 * 44, width: 390, height: height)
            #expect(layout.shouldInvalidateLayout(forPreferredLayoutAttributes: preferred, withOriginalAttributes: original) == expected)
        }
        #expect((0..<10).filter(layout.heights.isMeasured) == [4])
        #expect(layout.heights.height(at: 4) == 44)
    }

    /// A self-size moves the items below. Above the top edge it also moves the offset, so the screen stays still.
    @Test func selfSizeAdjustsTheOffsetOnlyAboveTheTop() {
        let layout = Self.layout(count: 100)
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 300, height: 400), collectionViewLayout: layout)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentOffset = CGPoint(x: 0, y: 440)
        for (item, expectedOffset) in [(2, 30), (20, 0)] as [(Int, CGFloat)] {
            let original = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: 0))
            original.frame = CGRect(x: 0, y: layout.heights.offset(of: item), width: 300, height: 44)
            let preferred = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: 0))
            preferred.frame = CGRect(x: 0, y: original.frame.minY, width: 300, height: 74)
            let context = layout.invalidationContext(forPreferredLayoutAttributes: preferred, withOriginalAttributes: original)
            #expect(context.contentSizeAdjustment.height == CGFloat(30))
            #expect(context.contentOffsetAdjustment.y == expectedOffset, "item \(item)")
            #expect(layout.heights.height(at: item) == 74 && layout.heights.isMeasured(item))
        }
        #expect(layout.heights.totalHeight == CGFloat(100 * 44 + 60))
    }

    // MARK: - Sections

    /// Ten items in four sections. Section 1 is empty.
    private static func sectionedLayout() -> MarkdownRowLayout {
        let layout = Self.layout(count: 10)
        layout.sectionStarts = [0, 3, 3, 7]
        return layout
    }

    @Test func sectionMathWithAnEmptySection() {
        let layout = Self.sectionedLayout()
        #expect((0..<4).map(layout.itemCount(inSection:)) == [3, 0, 4, 3])
        #expect((0..<10).map(layout.section(ofItem:)) == [0, 0, 0, 2, 2, 2, 2, 3, 3, 3])
        #expect(layout.indexPath(ofItem: 3) == IndexPath(item: 0, section: 2))
        #expect(layout.indexPath(ofItem: 9) == IndexPath(item: 2, section: 3))
        #expect(layout.item(at: IndexPath(item: 1, section: 2)) == 4)
        #expect(layout.item(at: IndexPath(item: 0, section: 3)) == 7)
    }

    @Test func itemAndIndexPathAreInverse() {
        let layout = Self.sectionedLayout()
        for item in 0..<10 {
            #expect(layout.item(at: layout.indexPath(ofItem: item)) == item, "item \(item)")
        }
    }

    @Test func attributesUseTheSectionIndexPaths() throws {
        let layout = Self.sectionedLayout()
        let paths = try #require(layout.layoutAttributesForElements(in: CGRect(x: 0, y: 0, width: 300, height: 1_000))).map(\.indexPath)
        #expect(paths == (0..<10).map(layout.indexPath(ofItem:)))
        let attributes = try #require(layout.layoutAttributesForItem(at: IndexPath(item: 1, section: 2)))
        #expect(attributes.frame.minY == CGFloat(4 * 44))
        #expect(layout.layoutAttributesForItem(at: IndexPath(item: 0, section: 4)) == nil)
    }

    // MARK: - Cell

    @Test func cellSkipsSizingWhenMeasuredAtTheCurrentKey() throws {
        let counter = SizingCounter()
        let cell = MarkdownRowCell(frame: CGRect(x: 0, y: 0, width: 300, height: 44))
        cell.contentConfiguration = TestRowContent(item: 7, height: 37, counter: counter)
        let attributes = MarkdownRowLayoutAttributes(forCellWith: IndexPath(item: 7, section: 0))
        attributes.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        attributes.sizingKey = MarkdownRowSizingKey(
            width: 300,
            contentSizeCategory: cell.traitCollection.preferredContentSizeCategory,
            legibilityWeight: cell.traitCollection.legibilityWeight
        )

        // Not measured: the cell measures its content at the attributes' width.
        let sized = cell.preferredLayoutAttributesFitting(attributes)
        #expect(sized.size == CGSize(width: 300, height: 37))
        #expect(counter.total == 1)

        // Measured under the same key: no sizing.
        attributes.isMeasured = true
        #expect(cell.preferredLayoutAttributesFitting(attributes).size == CGSize(width: 300, height: 44))
        #expect(counter.total == 1)

        // Measured, but at another width or text size: the cell sizes again.
        attributes.sizingKey.width = 320
        #expect(cell.preferredLayoutAttributesFitting(attributes).size == CGSize(width: 300, height: 37))
        attributes.sizingKey.width = 300
        attributes.sizingKey.contentSizeCategory = .accessibilityExtraLarge
        #expect(cell.preferredLayoutAttributesFitting(attributes).size == CGSize(width: 300, height: 37))
        #expect(counter.total == 3)
    }

    /// A content height between two points is rounded up, and an empty row keeps 1 pt.
    @Test func cellRoundsTheHeightUp() {
        let counter = SizingCounter()
        let cell = MarkdownRowCell(frame: .zero)
        let attributes = MarkdownRowLayoutAttributes(forCellWith: IndexPath(item: 0, section: 0))
        attributes.frame = CGRect(x: 0, y: 0, width: 250, height: 44)
        for (height, expected) in [(20.2, 21.0), (0, 1)] as [(CGFloat, CGFloat)] {
            cell.contentConfiguration = TestRowContent(item: 0, height: height, counter: counter)
            #expect(cell.preferredLayoutAttributesFitting(attributes).size == CGSize(width: 250, height: expected))
        }
    }
}
