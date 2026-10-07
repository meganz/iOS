@testable import MEGAMarkdown
import Testing
import UIKit

/// Items with fixed heights and a text field each. Estimates are a flat guess, or exact when `estimate` is nil.
@MainActor
final class FakeRowSource: MarkdownRowListDataSource {
    var heights: [CGFloat]
    var texts: [String]
    var estimate: CGFloat?
    var alwaysSizedItems: Set<Int> = []
    let counter = SizingCounter()

    init(count: Int, estimate: CGFloat? = 50) {
        heights = (0..<count).map { CGFloat(30 + ($0 * 17) % 50) }
        texts = (0..<count).map { "Item \($0)" }
        self.estimate = estimate
    }

    var itemCount: Int { heights.count }

    func configure(_ cell: MarkdownRowCell, forItem item: Int) {
        cell.contentConfiguration = TestRowContent(item: item, height: heights[item], text: texts[item], counter: counter)
    }

    func estimatedHeight(ofItem item: Int, using estimator: MarkdownRowEstimator) -> CGFloat {
        estimate ?? heights[item]
    }

    func alwaysSizes(item: Int) -> Bool {
        alwaysSizedItems.contains(item)
    }

    /// Plain prefix sums of the real heights.
    func offset(of item: Int) -> CGFloat {
        heights[..<item].reduce(0, +)
    }
}

/// The row list in a window, with a fake data source.
@MainActor
@Suite(.serialized, .timeLimit(.minutes(1)))
struct MarkdownRowListTests {
    private static let size = CGSize(width: 390, height: 844)

    @MainActor
    private final class Host {
        let window: UIWindow
        let list: MarkdownRowList
        let source: FakeRowSource

        init(source: FakeRowSource) {
            self.source = source
            list = MarkdownRowList(dataSource: source)
            list.view.contentInsetAdjustmentBehavior = .never
            let controller = UIViewController()
            controller.view = list.view
            window = UIWindow(frame: CGRect(origin: .zero, size: MarkdownRowListTests.size))
            window.rootViewController = controller
            window.makeKeyAndVisible()
            window.layoutIfNeeded()
            list.reloadAll()
        }

        var view: MarkdownRowListView { list.view }

        func close() {
            window.endEditing(true)
            window.rootViewController = nil
            window.isHidden = true
        }

        func textField(_ item: Int) -> UITextField? {
            contentView(item)?.textField
        }

        func contentView(_ item: Int) -> TestRowContentView? {
            list.cell(forItem: item)?.contentView as? TestRowContentView
        }

        var visibleItems: [Int] {
            view.indexPathsForVisibleItems.map(\.item).sorted()
        }

        /// Runs layout passes until nothing moves any more.
        func settle() async throws {
            var last = ""
            try await MarkdownRowListTests.waitUntil {
                view.layoutIfNeeded()
                let state = "\(view.contentSize.height) \(view.contentOffset.y) \(visibleItems) \(view.visibleCells.map(\.frame))"
                defer { last = state }
                return state == last
            }
        }

        func scroll(to y: CGFloat) async throws {
            view.contentOffset.y = y
            try await settle()
        }
    }

    private struct TimedOut: Error {}

    /// Polls `condition` every 10 ms. Throws when it is still false after `timeout`.
    private static func waitUntil(timeout: Duration = .seconds(10), _ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            guard ContinuousClock.now < deadline else { throw TimedOut() }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    // MARK: - Focus

    /// A kept item stays in the same cell and the same content view, so its text field keeps the focus.
    @Test func replaceKeepsTheFirstItemCellAndFocus() async throws {
        let host = Host(source: FakeRowSource(count: 100))
        defer { host.close() }
        try await host.settle()
        let cell = try #require(host.list.cell(forItem: 3))
        let content = try #require(host.contentView(3))
        let field = content.textField
        #expect(field.becomeFirstResponder())
        let applies = content.applyCount

        // Item 3 gets new text and items 4 and 5 become three items.
        host.source.texts[3] = "Item 3 changed"
        host.source.heights.replaceSubrange(3..<6, with: [44, 61, 62, 63])
        host.source.texts.replaceSubrange(4..<6, with: ["New 4", "New 5", "New 6"])
        host.list.replaceItems(3..<6, newCount: 4, keepingFirst: 1)
        try await host.settle()

        #expect(host.list.cell(forItem: 3) === cell)
        #expect(host.contentView(3) === content)
        #expect(content.applyCount > applies)
        #expect(field.text == "Item 3 changed")
        #expect(field.isFirstResponder)
        #expect(host.list.itemCount == 101)
        for item in 3...6 {
            #expect(host.list.itemFrame(at: item).height == host.source.heights[item], "item \(item)")
            #expect(host.textField(item)?.text == host.source.texts[item], "item \(item)")
        }
    }

    /// A height change of one item moves only the items below it. The cell is not configured again.
    @Test func invalidateHeightMovesOnlyItemsBelow() async throws {
        let host = Host(source: FakeRowSource(count: 60, estimate: nil))
        defer { host.close() }
        try await host.settle()
        let content = try #require(host.contentView(5))
        #expect(content.textField.becomeFirstResponder())
        let applies = content.applyCount
        // Items 0 to 9 end far above the bottom edge, so they stay on screen after the change.
        let before = Dictionary(uniqueKeysWithValues: (0..<10).map { ($0, host.list.cell(forItem: $0)?.frame ?? .null) })

        host.source.heights[5] += 40
        // The content view reads its height from the configuration, as a text view would read its text.
        content.configuration = TestRowContent(item: 5, height: host.source.heights[5], text: "Item 5", counter: host.source.counter)
        let appliesAfterEdit = content.applyCount
        host.list.invalidateHeight(ofItem: 5)
        try await host.settle()

        #expect(appliesAfterEdit == applies + 1)
        #expect(content.applyCount == appliesAfterEdit)
        #expect(host.contentView(5) === content)
        #expect(content.textField.isFirstResponder)
        #expect(host.view.contentOffset.y == 0)
        for (item, frame) in before {
            let now = host.list.cell(forItem: item)?.frame
            switch item {
            case ..<5: #expect(now == frame, "item \(item)")
            case 5: #expect(now == CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height + 40))
            default: #expect(now == frame.offsetBy(dx: 0, dy: 40), "item \(item)")
            }
        }
    }

    /// A pinned item keeps its cell, and the focus, while the list scrolls far away and back.
    @Test func pinnedItemKeepsItsCellFarOffScreen() async throws {
        let host = Host(source: FakeRowSource(count: 2_000))
        defer { host.close() }
        try await host.settle()
        let cell = try #require(host.list.cell(forItem: 2))
        let field = try #require(host.textField(2))
        #expect(field.becomeFirstResponder())
        host.list.pinnedItem = 2

        for screen in 1...20 {
            try await host.scroll(to: CGFloat(screen) * Self.size.height)
        }
        #expect(host.list.topItem > 300)
        #expect(host.list.cell(forItem: 2) === cell)
        #expect(cell.superview === host.view)
        #expect(field.isFirstResponder)

        try await host.scroll(to: 0)
        #expect(host.list.cell(forItem: 2) === cell)
        #expect(field.isFirstResponder)
    }

    // MARK: - Animation

    /// No layout pass may add an animation to a cell or its content. A row would slide in from far away.
    @Test func noAnimationsWhileScrollingSizingAppendingAndReplacing() async throws {
        let host = Host(source: FakeRowSource(count: 400))
        defer { host.close() }

        func expectStill(_ step: String, sourceLocation: SourceLocation = #_sourceLocation) {
            host.view.layoutIfNeeded()
            let animated = host.view.visibleCells.filter { Self.hasAnimation($0.layer) }
            #expect(animated.isEmpty, "\(step): \(animated.count) animated cells", sourceLocation: sourceLocation)
            #expect(!host.view.visibleCells.isEmpty, "\(step)", sourceLocation: sourceLocation)
        }

        // The first pass sizes every visible cell: the estimates are 50 pt, the real heights 30 to 79 pt.
        expectStill("open")
        for screen in 1...5 {
            host.view.contentOffset.y = CGFloat(screen) * 600
            expectStill("scroll \(screen)")
        }
        host.view.contentOffset.y -= 300
        expectStill("scroll up")

        host.source.heights += Array(repeating: 70, count: 50)
        host.source.texts += Array(repeating: "Appended", count: 50)
        host.list.appendItems(count: 50)
        expectStill("append")

        let top = host.list.topItem
        host.source.heights.replaceSubrange(top..<(top + 3), with: [90, 91])
        host.source.texts.replaceSubrange(top..<(top + 3), with: ["A", "B"])
        host.list.replaceItems(top..<(top + 3), newCount: 2, keepingFirst: 1)
        expectStill("replace")

        host.source.heights[top] = 120
        host.list.reconfigureItems([top])
        expectStill("reconfigure")
    }

    private static func hasAnimation(_ layer: CALayer) -> Bool {
        if !(layer.animationKeys() ?? []).isEmpty { return true }
        return (layer.sublayers ?? []).contains { hasAnimation($0) }
    }

    // MARK: - Sizing

    /// A cell sizes itself once. Scrolled back into view, a measured item is not sized again.
    @Test func measuredItemsAreNotSizedAgain() async throws {
        let host = Host(source: FakeRowSource(count: 300))
        defer { host.close() }
        try await host.settle()
        let counter = host.source.counter
        for screen in 1...6 {
            try await host.scroll(to: CGFloat(screen) * 400)
        }
        let afterDown = counter.total
        let countsAfterDown = counter.byItem
        #expect(afterDown > 40)
        #expect(counter.byItem.values.allSatisfy { $0 == 1 }, "\(counter.byItem.filter { $0.value != 1 })")

        for screen in (0...5).reversed() {
            try await host.scroll(to: CGFloat(screen) * 400)
        }
        #expect(host.visibleItems.first == 0)
        #expect(counter.total == afterDown, "\(counter.byItem.filter { countsAfterDown[$0.key] != $0.value })")
    }

    /// An item that sizes itself by itself is sized every time it shows again.
    @Test func alwaysSizedItemIsSizedAgain() async throws {
        let source = FakeRowSource(count: 300)
        source.alwaysSizedItems = [1]
        let host = Host(source: source)
        defer { host.close() }
        try await host.settle()
        let first = source.counter.byItem[1] ?? 0
        #expect(first >= 1)
        try await host.scroll(to: 5_000)
        try await host.scroll(to: 0)
        #expect((source.counter.byItem[1] ?? 0) > first)
        #expect(source.counter.byItem[0] == 1)
    }

    /// Items appended at the end do not move the items on screen.
    @Test func appendKeepsTheVisibleItemStill() async throws {
        let host = Host(source: FakeRowSource(count: 200))
        defer { host.close() }
        try await host.scroll(to: 3_000)
        let top = host.list.topItem
        let frame = try #require(host.list.cell(forItem: top)?.frame)
        let offset = host.view.contentOffset.y

        host.source.heights += Array(repeating: 33, count: 500)
        host.source.texts += Array(repeating: "Appended", count: 500)
        host.list.appendItems(count: 500)
        try await host.settle()

        #expect(host.list.itemCount == 700)
        #expect(host.list.topItem == top)
        #expect(host.view.contentOffset.y == offset)
        #expect(host.list.cell(forItem: top)?.frame == frame)
    }

    // MARK: - Sections

    /// 100 items, then 3 appends of 50. Sections start at 0, 100, 150 and 200.
    private static func hostWithSections() -> Host {
        let host = Host(source: FakeRowSource(count: 100, estimate: nil))
        for _ in 0..<3 { append(50, to: host) }
        return host
    }

    private static func append(_ count: Int, to host: Host) {
        host.source.heights += Array(repeating: 33, count: count)
        host.source.texts += (0..<count).map { "Appended \($0)" }
        host.list.appendItems(count: count)
    }

    @Test func eachAppendAddsExactlyOneSection() async throws {
        let host = Host(source: FakeRowSource(count: 100))
        defer { host.close() }
        #expect(host.view.numberOfSections == 1)
        Self.append(500, to: host)
        #expect(host.view.numberOfSections == 2)
        Self.append(1, to: host)
        #expect(host.view.numberOfSections == 3)
        #expect(host.list.itemCount == 601)
        #expect(host.view.numberOfItems(inSection: 1) == 500)
    }

    @Test func appendOnAnEmptyListReloadsInOneSection() async throws {
        let host = Host(source: FakeRowSource(count: 0))
        defer { host.close() }
        Self.append(20, to: host)
        #expect(host.view.numberOfSections == 1)
        #expect(host.list.itemCount == 20)
    }

    @Test func reloadAllResetsTheSections() async throws {
        let host = Self.hostWithSections()
        defer { host.close() }
        #expect(host.view.numberOfSections == 4)
        host.list.reloadAll()
        #expect(host.view.numberOfSections == 1)
        #expect(host.view.numberOfItems(inSection: 0) == 250)
    }

    @Test func itemsInALaterSectionWork() async throws {
        let host = Self.hostWithSections()
        defer { host.close() }
        try await host.settle()
        let item = 230
        host.list.scrollToItem(item, rect: nil) {}
        try await host.settle()

        #expect(host.list.item(for: IndexPath(item: 30, section: 3)) == item)
        let cell = try #require(host.list.cell(forItem: item))
        #expect(host.textField(item)?.text == host.source.texts[item])
        #expect(host.list.item(at: CGPoint(x: 10, y: cell.frame.midY)) == item)

        host.source.texts[item] = "Changed"
        host.list.reconfigureItems([item])
        try await host.settle()
        #expect(host.list.cell(forItem: item) === cell)
        #expect(host.textField(item)?.text == "Changed")

        let applies = try #require(host.contentView(item)).applyCount
        host.source.heights[item] += 40
        host.contentView(item)?.configuration = TestRowContent(item: item, height: host.source.heights[item], text: "Changed", counter: host.source.counter)
        host.list.invalidateHeight(ofItem: item)
        try await host.settle()
        #expect(host.contentView(item)?.applyCount == applies + 1)
        #expect(host.list.cell(forItem: item)?.frame.height == host.source.heights[item])
    }

    /// The visible top item does not move when a range below it, in a later section, changes.
    @Test func replaceInALaterSectionKeepsTheTopItemStill() async throws {
        let host = Self.hostWithSections()
        defer { host.close() }
        try await host.settle()
        try await host.scroll(to: host.list.itemFrame(at: 205).minY)
        let top = host.list.topItem
        let frame = try #require(host.list.cell(forItem: top)?.frame)

        host.source.heights.replaceSubrange(230..<233, with: [50, 60])
        host.source.texts.replaceSubrange(230..<233, with: ["A", "B"])
        host.list.replaceItems(230..<233, newCount: 2, keepingFirst: 1)
        try await host.settle()

        #expect(host.view.numberOfSections == 4)
        #expect(host.list.itemCount == 249)
        #expect(host.list.topItem == top)
        #expect(host.list.cell(forItem: top)?.frame == frame)
        try await host.scroll(to: host.list.itemFrame(at: 245).minY)
        for item in 245...248 {
            #expect(host.textField(item)?.text == host.source.texts[item], "item \(item)")
        }
    }

    /// A range across a section edge reads every item again, in one section. The top row stays.
    @Test func replaceAcrossASectionEdgeReloadsAll() async throws {
        let host = Self.hostWithSections()
        defer { host.close() }
        try await host.settle()
        try await host.scroll(to: host.list.itemFrame(at: 20).minY)
        let top = host.list.topItem
        let offset = host.view.contentOffset.y

        host.source.texts.replaceSubrange(95..<105, with: Array(repeating: "New", count: 10))
        host.list.replaceItems(95..<105, newCount: 10, keepingFirst: 0)
        try await host.settle()

        #expect(host.view.numberOfSections == 1)
        #expect(host.list.itemCount == 250)
        #expect(host.list.topItem == top)
        #expect(host.view.contentOffset.y == offset)
    }

    // MARK: - Geometry

    @Test func itemFramesAndHitTestsWithoutCells() async throws {
        let host = Host(source: FakeRowSource(count: 1_000, estimate: nil))
        defer { host.close() }
        try await host.settle()
        let source = host.source
        for item in [0, 1, 17, 500, 999] {
            let y = source.offset(of: item)
            #expect(host.list.itemFrame(at: item) == CGRect(x: 0, y: y, width: Self.size.width, height: source.heights[item]), "item \(item)")
            #expect(host.list.item(at: CGPoint(x: 10, y: y)) == item)
            #expect(host.list.item(at: CGPoint(x: 10, y: y + source.heights[item] - 0.5)) == item)
        }
        #expect(host.list.cell(forItem: 500) == nil)
        #expect(host.list.item(at: CGPoint(x: 10, y: -1)) == nil)
        #expect(host.list.item(at: CGPoint(x: 10, y: source.offset(of: 1_000))) == nil)
    }

    /// The completion runs after the layout pass, so the item's cell exists and the rect is on screen.
    @Test func scrollToItemCompletionHasTheCell() async throws {
        let host = Host(source: FakeRowSource(count: 1_000))
        defer { host.close() }
        try await host.settle()
        var cell: MarkdownRowCell?
        var visibleRect = CGRect.null
        host.list.scrollToItem(700, rect: CGRect(x: 0, y: 10, width: 10, height: 20)) {
            cell = host.list.cell(forItem: 700)
            visibleRect = host.view.bounds
        }
        let found = try #require(cell)
        let caret = CGRect(x: 0, y: found.frame.minY + 10, width: 10, height: 20)
        #expect(visibleRect.contains(caret))
        #expect(host.list.itemFrame(at: 700) == found.frame)
    }

    /// After a width change the top item stays at the top.
    @Test func widthChangeKeepsTheTopItem() async throws {
        let host = Host(source: FakeRowSource(count: 1_000))
        defer { host.close() }
        try await host.scroll(to: 10_000)
        // The top item starts at the top edge. A self-size of an item that crosses the edge moves the offset.
        let top = host.list.topItem
        try await host.scroll(to: host.list.itemFrame(at: top).minY)
        #expect(host.list.topItem == top)

        host.window.frame = CGRect(x: 0, y: 0, width: 600, height: Self.size.height)
        host.window.layoutIfNeeded()
        try await host.settle()

        #expect(host.view.bounds.width == 600)
        #expect(host.list.topItem == top)
        #expect(host.list.itemFrame(at: top).minY == host.view.contentOffset.y)
    }
}
