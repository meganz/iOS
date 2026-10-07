@testable import MEGAMarkdown
import SwiftUI
import Testing
import UIKit

/// The preview list in a real window: restore, top-line reports, new text and appended rows.
@MainActor
@Suite(.serialized, .timeLimit(.minutes(1)))
struct PreviewRowListRestoreTests {
    private typealias Window = PreviewListWindow

    /// One row per item, and item `n` is on line `n`.
    private static let listText = (0..<100_000).map { "- item \($0)" }.joined(separator: "\n")

    /// The target paragraph is on line 8,000. Below it: six short paragraphs, a 6-line code block on line 8,014
    /// and a table on line 8,023. 16 KB chunks put the target in a later batch.
    private static let targetLine = 8_000
    private static let bugText: String = {
        let filler = { (range: Range<Int>) in range.map { "Para \($0) with some words here." } }
        let code = "```swift\n" + (1...6).map { "let value\($0) = \($0)" }.joined(separator: "\n") + "\n```"
        let table = "| Name | Value |\n|---|---|\n| a | 1 |\n| b | 2 |\n| c | 3 |"
        let parts = filler(0..<4_000) + ["Target paragraph."] + (1...6).map { "Short \($0)." } + [code, table] + filler(4_000..<6_000)
        return parts.joined(separator: "\n\n")
    }()

    private static let smallChunks = PreviewParseLimits(targetChunkBytes: 16_384)

    private struct Opened {
        let host: Window
        let feed: PreviewFeed
        let recorder: LineRecorder
        let list: MarkdownRowListView
    }

    private func open(_ markdown: String, restoreLine: Int?, limits: PreviewParseLimits = smallChunks, batches: Int? = nil) async throws -> Opened {
        let feed = PreviewFeed()
        feed.restoreLine = restoreLine
        feed.load(markdown, limits: limits, batches: batches)
        let recorder = LineRecorder()
        let host = Window(PreviewFeedHost(feed: feed, recorder: recorder))
        let list = try await host.shownList()
        return Opened(host: host, feed: feed, recorder: recorder, list: list)
    }

    // MARK: - Restore

    @Test func restoredRowIsAtTheTop() async throws {
        let opened = try await open(Self.listText, restoreLine: 50_000)
        defer { opened.host.close() }
        try await Window.waitUntil { try Window.topVisibleLine(opened.list) == 50_000 }
        try await Window.settle(opened.list)
        #expect(try Window.topVisibleLine(opened.list) == 50_000)
        #expect(opened.recorder.lines == [50_000])
    }

    @Test func restoreWorksRightToLeft() async throws {
        let feed = PreviewFeed()
        feed.restoreLine = 50_000
        feed.layoutDirection = .rightToLeft
        feed.load(Self.listText)
        let recorder = LineRecorder()
        let host = Window(PreviewFeedHost(feed: feed, recorder: recorder))
        defer { host.close() }
        let list = try await host.shownList()
        try await Window.settle(list)
        #expect(try Window.topVisibleLine(list) == 50_000)
        #expect(recorder.lines == [50_000])
    }

    /// The restore line is in a batch that arrives later. Nothing is reported before it, then its line is.
    @Test func restoreIntoALaterBatchReportsItsLine() async throws {
        let opened = try await open(Self.bugText, restoreLine: Self.targetLine, batches: 1)
        defer { opened.host.close() }
        let coordinator = try Window.coordinator(of: opened.list)
        try #require(opened.feed.rows.last.map { $0.sourceLine < Self.targetLine } == true)
        try await Window.settle(opened.list)
        #expect(coordinator.pendingRestoreLine == Self.targetLine)
        #expect(opened.recorder.lines.isEmpty)

        opened.feed.send(opened.feed.waiting.count)
        try await Window.waitUntil { opened.recorder.lines.last == Self.targetLine }
        try await Window.settle(opened.list)
        #expect(try Window.topVisibleLine(opened.list) == Self.targetLine)
        #expect(opened.recorder.lines == [Self.targetLine])
    }

    /// The code block below the restored row shows all its lines, also after a scroll away and back.
    @Test func restoredCodeBlockShowsAllLines() async throws {
        let opened = try await open(Self.bugText, restoreLine: Self.targetLine)
        defer { opened.host.close() }
        let list = opened.list
        try await Window.waitUntil { try Window.topVisibleLine(list) == Self.targetLine }
        try await Window.settle(list)
        try checkCodeRowIsShown(list)
        try Window.checkRowsAreComplete(list, "after restore")

        let target = try #require(try Window.coordinator(of: list).store.rowIndex(containing: Self.targetLine))
        list.contentOffset.y += 20 * list.bounds.height
        try await Window.settle(list)
        try await Window.scroll(list, toRow: target)
        try checkCodeRowIsShown(list)
        try Window.checkRowsAreComplete(list, "after scroll back")
    }

    private func checkCodeRowIsShown(_ list: MarkdownRowListView, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let coordinator = try Window.coordinator(of: list)
        let codeRow = Window.visibleCells(list).first { item, _ in
            if case .codePiece(_, let code, _, _) = coordinator.store[item].content { return code.hasPrefix("let value1") }
            return false
        }
        let item = try #require(codeRow?.item, "the code block must be on screen", sourceLocation: sourceLocation)
        guard case .codePiece(_, let code, true, true) = coordinator.store[item].content else {
            Issue.record("row \(item) is not the whole code block", sourceLocation: sourceLocation)
            return
        }
        #expect(code.components(separatedBy: "\n").count == 6, sourceLocation: sourceLocation)
    }

    @Test func widthChangeKeepsTheTopRow() async throws {
        let opened = try await open(Self.bugText, restoreLine: Self.targetLine)
        defer { opened.host.close() }
        let list = opened.list
        try await Window.waitUntil { try Window.topVisibleLine(list) == Self.targetLine }
        try await Window.settle(list)
        for size in [CGSize(width: 874, height: 402), Window.phoneSize] {
            opened.host.window.frame = CGRect(origin: .zero, size: size)
            opened.host.window.layoutIfNeeded()
            try await Window.waitUntil { list.bounds.width == size.width }
            try await Window.settle(list)
            #expect(try Window.topVisibleLine(list) == Self.targetLine, "top row at \(size)")
            try Window.checkRowsAreComplete(list, "at \(size)")
        }
    }

    @Test func restoreLinePastTheEndShowsTheLastRow() async throws {
        let opened = try await open(Self.listText, restoreLine: 10_000_000)
        defer { opened.host.close() }
        let list = opened.list
        try await Window.waitUntil { list.indexPathsForVisibleItems.contains { $0.item == 99_999 } }
        try await Window.settle(list)
        let top = try #require(try Window.topVisibleLine(list))
        #expect(top > 99_900)
        #expect(list.indexPathsForVisibleItems.contains { $0.item == 99_999 })
        // Rows near the end size themselves after the jump, so the top can move by a row. Each report is a real top line.
        #expect(opened.recorder.lines.last == top)
        #expect(opened.recorder.lines.allSatisfy { $0 > 99_900 && $0 <= 99_999 })
    }

    // MARK: - Pin

    /// A status bar tap scrolls to the top. The restore pin must not pull the list back.
    @Test func statusBarTapClearsThePin() async throws {
        let opened = try await open(Self.listText, restoreLine: 50_000)
        defer { opened.host.close() }
        let list = opened.list
        let coordinator = try Window.coordinator(of: list)
        try await Window.waitUntil { coordinator.pin != nil }
        #expect(coordinator.scrollViewShouldScrollToTop(list))
        #expect(coordinator.pin == nil)
        list.contentOffset.y = -list.adjustedContentInset.top
        try await Window.settle(list)
        #expect(try Window.topVisibleLine(list) == 0)
        #expect(opened.recorder.lines.last == 0)
    }

    @Test func dragClearsThePin() async throws {
        let opened = try await open(Self.listText, restoreLine: 50_000)
        defer { opened.host.close() }
        let list = opened.list
        let coordinator = try Window.coordinator(of: list)
        try await Window.waitUntil { coordinator.pin != nil }
        coordinator.scrollViewWillBeginDragging(list)
        #expect(coordinator.pin == nil)
        list.contentOffset.y += 3 * list.bounds.height
        try await Window.settle(list)
        #expect(try #require(try Window.topVisibleLine(list)) > 50_000)
    }

    // MARK: - Reports

    @Test func scrollReportsTheNewTopLine() async throws {
        let opened = try await open(Self.listText, restoreLine: nil)
        defer { opened.host.close() }
        let list = opened.list
        try await Window.settle(list)
        #expect(opened.recorder.lines == [0])
        try await Window.scroll(list, toRow: 3_000)
        let shown = try #require(try Window.topVisibleLine(list))
        #expect(shown == 3_000)
        #expect(opened.recorder.lines.last == shown)
    }

    @Test func noReportAfterTheViewIsGone() async throws {
        let opened = try await open(Self.listText, restoreLine: nil)
        defer { opened.host.close() }
        let list = opened.list
        let coordinator = try Window.coordinator(of: list)
        try await Window.settle(list)
        opened.feed.isShown = false
        try await Window.waitUntil { opened.host.list == nil }
        let count = opened.recorder.lines.count

        // The list view lives on here. Its layout passes and scrolls must not report.
        list.contentOffset.y += 10 * list.bounds.height
        coordinator.scrollViewDidScroll(list)
        list.setNeedsLayout()
        list.layoutIfNeeded()
        #expect(coordinator.isStopped)
        #expect(opened.recorder.lines.count == count)
    }

    // MARK: - New text and appended rows

    @Test func newTextGoesToTheTop() async throws {
        let opened = try await open(Self.listText, restoreLine: nil)
        defer { opened.host.close() }
        let list = opened.list
        try await Window.scroll(list, toRow: 3_000)
        #expect(try Window.topVisibleLine(list) == 3_000)

        opened.feed.load((0..<1_000).map { "- other \($0)" }.joined(separator: "\n"))
        try await Window.waitUntil { try Window.coordinator(of: list).store.count == 1_000 }
        try await Window.settle(list)
        #expect(list.contentOffset.y == -list.adjustedContentInset.top)
        #expect(try Window.topVisibleLine(list) == 0)
        #expect(opened.recorder.lines.last == 0)
    }

    /// Rows that arrive later go below. The rows on screen do not move.
    @Test func appendKeepsTheVisibleRowStill() async throws {
        let opened = try await open(Self.bugText, restoreLine: nil, batches: 1)
        defer { opened.host.close() }
        let list = opened.list
        let firstCount = opened.feed.rowCount
        try await Window.scroll(list, toRow: firstCount / 2)
        let offset = list.contentOffset.y
        let frames = Window.visibleCells(list).map(\.cell.frame)

        opened.feed.send(opened.feed.waiting.count)
        try await Window.waitUntil { try Window.coordinator(of: list).list.itemCount == opened.feed.rowCount }
        try await Window.settle(list)
        #expect(opened.feed.rowCount > firstCount)
        #expect(list.contentOffset.y == offset)
        #expect(Window.visibleCells(list).map(\.cell.frame) == frames)
    }

    /// Rows measured once keep their height when they show again.
    @Test func scrollBackKeepsTheMeasuredHeights() async throws {
        let opened = try await open(Self.bugText, restoreLine: nil)
        defer { opened.host.close() }
        let list = opened.list
        let layout = try Window.layout(of: list)
        try await Window.settle(list)
        let items = Window.visibleCells(list).map(\.item)
        let heights = items.map { layout.heights.height(at: $0) }
        #expect(items.allSatisfy { layout.heights.isMeasured($0) })
        let frames = Window.visibleCells(list).map(\.cell.frame)

        try await Window.scroll(list, toRow: 1_000)
        try await Window.scroll(list, toRow: 0)
        #expect(Window.visibleCells(list).map(\.item) == items)
        #expect(items.map { layout.heights.height(at: $0) } == heights)
        #expect(items.allSatisfy { layout.heights.isMeasured($0) })
        #expect(Window.visibleCells(list).map(\.cell.frame) == frames)
    }
}
