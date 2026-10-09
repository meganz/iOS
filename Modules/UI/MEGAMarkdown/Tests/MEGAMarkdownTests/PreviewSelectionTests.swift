@testable import MEGAMarkdown
import SwiftUI
import Testing
import UIKit

/// Block selection in the preview list, in a real window, through the selection controller's touch calls
/// (the calls the long press and the list watcher make). Checked on iOS 18.6 and 26.4 simulators only.
@MainActor
@Suite(.serialized, .timeLimit(.minutes(1)))
struct PreviewSelectionTests {
    private typealias Window = PreviewListWindow

    private static let fourParagraphs = "Paragraph zero.\n\nParagraph one.\n\nParagraph two.\n\nParagraph three."
    /// 250 code lines: three code pieces of at most 100 lines.
    private static let bigCode = (0..<250).map { "line \($0)" }.joined(separator: "\n")

    private struct Opened {
        let host: Window
        let feed: PreviewFeed
        let list: MarkdownRowListView
        let selection: PreviewSelectionController
    }

    private func open(_ markdown: String, layoutDirection: LayoutDirection = .leftToRight,
                      limits: PreviewParseLimits = PreviewParseLimits()) async throws -> Opened {
        let feed = PreviewFeed()
        feed.layoutDirection = layoutDirection
        feed.load(markdown, limits: limits)
        let host = Window(PreviewFeedHost(feed: feed, recorder: LineRecorder()))
        let list = try await host.shownList()
        try await Window.settle(list)
        let selection = try Window.coordinator(of: list).selection
        return Opened(host: host, feed: feed, list: list, selection: selection)
    }

    private func center(ofRow row: Int, _ opened: Opened) throws -> CGPoint {
        let cell = try #require(Window.visibleCells(opened.list).first { $0.item == row }?.cell)
        return CGPoint(x: cell.frame.midX, y: cell.frame.midY)
    }

    /// A long press that does not move: it selects the block at the row.
    private func selectBlock(atRow row: Int, _ opened: Opened) throws {
        opened.selection.longPressBegan(at: try center(ofRow: row, opened))
        opened.selection.longPressEnded()
    }

    // MARK: - Long press

    /// A long press on one piece of a split code block selects every piece of it.
    @Test func longPressSelectsTheWholeSplitBlock() async throws {
        let opened = try await open("Before.\n\n```\n\(Self.bigCode)\n```\n\nAfter.")
        defer { opened.host.close() }
        let codeRows = opened.feed.rows.indices.filter { if case .codePiece = opened.feed.rows[$0].content { true } else { false } }
        #expect(codeRows.count == 3)
        try await Window.scroll(opened.list, toRow: codeRows[1])

        opened.selection.longPressBegan(at: try center(ofRow: codeRows[1], opened))
        opened.selection.longPressEnded()

        #expect(opened.selection.selectedRows == codeRows.first!...codeRows.last!)
        #expect(opened.selection.isDisplayActive)
        #expect(opened.selection.responder.isFirstResponder)
        #expect(opened.selection.selectedText() == Self.bigCode)
    }

    /// A code piece of 100 lines is taller than the screen. The menu points at the part on screen.
    @Test func menuBoundsStayOnScreenOverATallBlock() async throws {
        let opened = try await open("```\n\(Self.bigCode)\n```")
        defer { opened.host.close() }
        try #require(opened.list.cellForItem(at: IndexPath(item: 0, section: 0))?.frame.height ?? 0 > opened.list.bounds.height)

        opened.selection.longPressBegan(at: try center(ofRow: 0, opened))
        opened.selection.longPressEnded()

        let bounds = try #require(opened.selection.visibleSelectionBounds())
        #expect(opened.list.bounds.contains(bounds))
    }

    /// Each batch adds a list section, so a row's item in its section is not its row number.
    @Test func selectionInALaterBatchDrawsOnItsRow() async throws {
        let markdown = (0..<60).map { "Paragraph \($0)." }.joined(separator: "\n\n")
        let feed = PreviewFeed()
        // The first batch can be empty with a 1-byte chunk target, so three batches go first.
        feed.load(markdown, limits: PreviewParseLimits(targetChunkBytes: 1, maxChunkBytes: 1_000), batches: 3)
        let host = Window(PreviewFeedHost(feed: feed, recorder: LineRecorder()))
        defer { host.close() }
        let list = try await host.shownList()
        try await Window.settle(list)
        while !feed.waiting.isEmpty {
            feed.send(20)
            try await Window.settle(list)
        }
        try #require(list.numberOfSections > 1)
        let row = feed.store.count - 1
        try await Window.scroll(list, toRow: row)
        let cell = try #require(Window.visibleCells(list).first { $0.item == row }?.cell)
        let selection = try Window.coordinator(of: list).selection

        selection.longPressBegan(at: CGPoint(x: cell.frame.midX, y: cell.frame.midY))
        selection.longPressEnded()

        #expect(selection.selectedRows == row...row)
        let span = try #require(selection.displayInput.span)
        let drawn = selection.selectionRects(for: span).map(\.rect).filter { $0.width > 0 }
        #expect(drawn.count == 1)
        #expect(drawn.first?.minY == cell.frame.minY)
        let bounds = try #require(selection.visibleSelectionBounds())
        #expect(cell.frame.intersects(bounds))
    }

    @Test func longPressDragGrowsByBlocks() async throws {
        let opened = try await open(Self.fourParagraphs)
        defer { opened.host.close() }

        opened.selection.longPressBegan(at: try center(ofRow: 1, opened))
        let target = try center(ofRow: 3, opened)
        opened.selection.longPressMoved(to: target, inWindow: opened.list.convert(target, to: nil))
        opened.selection.longPressEnded()

        #expect(opened.selection.selectedRows == 1...3)
    }

    // MARK: - Handles

    @Test func endHandleGrowsAndShrinksByWholeBlocks() async throws {
        let opened = try await open(Self.fourParagraphs)
        defer { opened.host.close() }
        try selectBlock(atRow: 0, opened)
        let span = try #require(opened.selection.displayInput.span)
        let endCaret = try #require(opened.selection.caretRect(for: span.end))
        let grab = CGPoint(x: endCaret.midX, y: endCaret.maxY + 4)

        opened.selection.touchBegan(at: grab, others: [])
        let row2 = try center(ofRow: 2, opened)
        #expect(opened.selection.touchMoved(to: row2, inWindow: opened.list.convert(row2, to: nil), others: []))
        #expect(opened.selection.selectedRows == 0...2)
        let row1 = try center(ofRow: 1, opened)
        _ = opened.selection.touchMoved(to: row1, inWindow: opened.list.convert(row1, to: nil), others: [])
        opened.selection.touchEnded(at: row1, listPanBegan: false, cancelled: false)

        #expect(opened.selection.selectedRows == 0...1)
        #expect(opened.list.panGestureRecognizer.isEnabled)
    }

    /// The start handle dragged below the anchor: the selection turns around and keeps whole blocks.
    @Test func startHandlePastTheAnchorTurnsTheSelection() async throws {
        let opened = try await open(Self.fourParagraphs)
        defer { opened.host.close() }
        try selectBlock(atRow: 1, opened)
        let span = try #require(opened.selection.displayInput.span)
        let startCaret = try #require(opened.selection.caretRect(for: span.start))
        let grab = CGPoint(x: startCaret.midX, y: startCaret.minY - 4)

        opened.selection.touchBegan(at: grab, others: [])
        let row3 = try center(ofRow: 3, opened)
        #expect(opened.selection.touchMoved(to: row3, inWindow: opened.list.convert(row3, to: nil), others: []))
        opened.selection.touchEnded(at: row3, listPanBegan: false, cancelled: false)

        #expect(opened.selection.selectedRows == 1...3)
    }

    /// A handle held at the bottom edge starts the autoscroll. After a scroll step the head is the row under the finger.
    @Test func handleAtTheBottomEdgeAutoscrolls() async throws {
        let text = (0..<200).map { "Paragraph \($0)." }.joined(separator: "\n\n")
        let opened = try await open(text)
        defer { opened.host.close() }
        try selectBlock(atRow: 0, opened)
        let span = try #require(opened.selection.displayInput.span)
        let endCaret = try #require(opened.selection.caretRect(for: span.end))
        let grab = CGPoint(x: endCaret.midX, y: endCaret.maxY + 4)
        let list = opened.list
        let bottom = CGPoint(x: list.bounds.midX, y: list.contentOffset.y + list.bounds.height - list.adjustedContentInset.bottom - 5)

        opened.selection.touchBegan(at: grab, others: [])
        #expect(opened.selection.touchMoved(to: bottom, inWindow: list.convert(bottom, to: nil), others: []))
        #expect(opened.selection.autoScroller?.isScrolling == true)
        // One scroll step by hand, so the result does not depend on display timing.
        opened.selection.autoScroller?.stop()
        list.contentOffset.y += 1_000
        list.layoutIfNeeded()
        opened.selection.autoscrolled()
        let headY = bottom.y + 1_000 + endCaret.midY - grab.y
        let expectedHead = try Window.layout(of: list).heights.index(at: headY)
        opened.selection.touchEnded(at: bottom, listPanBegan: false, cancelled: false)

        #expect(expectedHead > 20)
        #expect(opened.selection.selectedRows == 0...expectedHead)
    }

    /// A long press inside the selection selects the block under the finger. The touch keeps the long press alive.
    @Test func longPressInsideTheSelectionSelectsThatBlock() async throws {
        let opened = try await open(Self.fourParagraphs)
        defer { opened.host.close() }
        opened.selection.selectAll()
        let longPress = try #require(opened.selection.longPress)
        let link = UITapGestureRecognizer()
        let stopped = StopLog()
        let observers = [(longPress, "long press"), (link, "link")].map { recognizer, name in
            recognizer.observe(\.isEnabled, options: [.new]) { _, change in
                if change.newValue == false { stopped.names.append(name) }
            }
        }
        defer { observers.forEach { $0.invalidate() } }
        let inside = try center(ofRow: 2, opened)

        opened.selection.touchBegan(at: inside, others: [longPress, link, opened.list.panGestureRecognizer])
        opened.selection.longPressBegan(at: inside)
        opened.selection.longPressEnded()

        #expect(stopped.names == ["link"])
        #expect(opened.selection.selectedRows == 2...2)
    }

    @Test func longPressOnANoticeSelectsNothing() async throws {
        let markdown = "```\n" + String(repeating: "code line\n", count: 2_000) + "```\n"
        let opened = try await open(markdown, limits: PreviewParseLimits(targetChunkBytes: 1, maxChunkBytes: 1_000))
        defer { opened.host.close() }
        try #require(opened.feed.store.noticeRows == [0])
        let noticeRow = 0

        opened.selection.longPressBegan(at: try center(ofRow: noticeRow, opened))
        opened.selection.longPressEnded()

        #expect(opened.selection.selection == nil)
        #expect(!opened.selection.isDisplayActive)
    }

    /// The edit menu interaction goes with the rest, so a second attach adds only one.
    @Test func detachRemovesTheEditMenu() async throws {
        let opened = try await open(Self.fourParagraphs)
        defer { opened.host.close() }
        let menus = { opened.selection.responder.interactions.filter { $0 is UIEditMenuInteraction }.count }
        #expect(menus() == 1)

        opened.selection.detach()
        #expect(menus() == 0)
        opened.selection.attach()
        #expect(menus() == 1)
    }

    // MARK: - Taps and scrolls

    @Test func tapOutsideClearsAndTapInsideKeeps() async throws {
        let opened = try await open(Self.fourParagraphs)
        defer { opened.host.close() }
        try selectBlock(atRow: 1, opened)
        let inside = try center(ofRow: 1, opened)

        opened.selection.touchBegan(at: inside, others: [])
        opened.selection.touchEnded(at: inside, listPanBegan: false, cancelled: false)
        #expect(opened.selection.selectedRows == 1...1)

        let outside = try center(ofRow: 3, opened)
        opened.selection.touchBegan(at: outside, others: [])
        opened.selection.touchEnded(at: outside, listPanBegan: false, cancelled: false)
        #expect(opened.selection.selection == nil)
        #expect(!opened.selection.isDisplayActive)
    }

    /// A swipe that does not start on a handle is a scroll: no takeover, and the selection stays.
    @Test func swipeAwayFromTheHandlesScrolls() async throws {
        let opened = try await open(Self.fourParagraphs)
        defer { opened.host.close() }
        try selectBlock(atRow: 0, opened)
        let start = try center(ofRow: 2, opened)
        let end = CGPoint(x: start.x, y: start.y - 120)

        opened.selection.touchBegan(at: start, others: [])
        #expect(!opened.selection.touchMoved(to: end, inWindow: opened.list.convert(end, to: nil), others: []))
        opened.selection.touchEnded(at: end, listPanBegan: true, cancelled: false)

        #expect(opened.selection.selectedRows == 0...0)
    }

    // MARK: - Copy and Select All

    @Test func copyWritesPlainTextOnly() async throws {
        let markdown = """
        # Title

        Some **bold** text with a [link](https://mega.io).

        - item one
        - item two

        > A quote.

        ```
        code
        ```

        ---

        | a | b |
        |---|---|
        | 1 | 2 |
        """
        let opened = try await open(markdown)
        defer { opened.host.close() }

        let pasteboard = UIPasteboard.withUniqueName()
        defer { UIPasteboard.remove(withName: pasteboard.name) }
        opened.selection.pasteboard = pasteboard
        opened.selection.selectAll()
        opened.selection.copySelection()

        let expected = "Title\n\nSome bold text with a link.\n\nitem one\n\nitem two\n\nA quote.\n\ncode\n\na\tb\n1\t2"
        #expect(opened.selection.selectedText() == expected)
        #expect(pasteboard.string == expected)
        #expect(pasteboard.types == ["public.utf8-plain-text"])
    }

    /// A table of 120 rows is split into pages, and a code line of 20,000 characters is cut. Copy joins them back.
    @Test func copyJoinsTablePagesAndCutCodeLines() async throws {
        let table = "| n | square |\n|---|---|\n" + (0..<120).map { "| \($0) | \($0 * $0) |" }.joined(separator: "\n")
        let longLine = String(repeating: "x", count: 20_000)
        let opened = try await open(table + "\n\n```\n" + longLine + "\nend\n```")
        defer { opened.host.close() }

        opened.selection.selectAll()

        let tableText = (["n\tsquare"] + (0..<120).map { "\($0)\t\($0 * $0)" }).joined(separator: "\n")
        #expect(opened.selection.selectedText() == tableText + "\n\n" + longLine + "\nend")
    }

    /// Line 101 of the code starts a new piece and begins with the cut marker as written. It stays its own line.
    @Test func copyKeepsACodeLineThatStartsWithTheCutMarker() async throws {
        let code = ((0..<100).map { "line \($0)" } + [PreviewRows.codeContinuationMarker + "literal", "after"]).joined(separator: "\n")
        let opened = try await open("```\n" + code + "\n```")
        defer { opened.host.close() }

        opened.selection.selectAll()

        #expect(opened.feed.rows.count == 2)
        #expect(opened.selection.selectedText() == code)
    }

    @Test func selectAllSelectsEveryBlock() async throws {
        let opened = try await open(Self.fourParagraphs)
        defer { opened.host.close() }

        opened.selection.responder.selectAll(nil)

        #expect(opened.selection.selectedRows == 0...(opened.feed.rows.count - 1))
        #expect(opened.selection.responder.canPerformAction(#selector(UIResponder.copy(_:)), withSender: nil))
    }

    /// A new text drops the selection: its rows are gone.
    @Test func newTextClearsTheSelection() async throws {
        let opened = try await open(Self.fourParagraphs)
        defer { opened.host.close() }
        opened.selection.selectAll()

        opened.feed.load("Another text.")
        try await Window.waitUntil { opened.feed.rows.count == 1 && opened.selection.selection == nil }
    }

    // MARK: - Right to left

    @Test func rightToLeftPutsTheStartHandleOnTheRight() async throws {
        let opened = try await open("שלום עולם\n\nמה שלומך", layoutDirection: .rightToLeft)
        defer { opened.host.close() }
        opened.selection.selectAll()

        let span = try #require(opened.selection.displayInput.span)
        let start = try #require(opened.selection.caretRect(for: span.start))
        let end = try #require(opened.selection.caretRect(for: span.end))
        #expect(start.midX > opened.list.bounds.midX)
        #expect(end.midX < opened.list.bounds.midX)
        let startRects = opened.selection.selectionRects(for: span).filter(\.containsStart)
        #expect(startRects.first?.writingDirection == .rightToLeft)
    }
}

/// The recognizers a touch turned off. KVO calls back on the main thread, during the call that changes the value.
private final class StopLog: @unchecked Sendable {
    var names: [String] = []
}
