@testable import MEGAMarkdown
import SwiftUI
import Testing
import UIKit

/// Closing the preview notice in a real window. The test calls the action of the close button.
@MainActor
@Suite(.serialized, .timeLimit(.minutes(1)))
struct PreviewNoticeCloseTests {
    private typealias Window = PreviewListWindow

    /// An open fence with no safe cut: one notice row, then the rest as plain text rows.
    private static let markdown = "```\n" + String(repeating: "code line\n", count: 2_000) + "```\n"
    private static let limits = PreviewParseLimits(targetChunkBytes: 1, maxChunkBytes: 1_000)
    /// A cell measures at least 1 pt, so a closed notice keeps 1 pt.
    private static let closedHeight: CGFloat = 1

    private func height(ofItem item: Int, in list: MarkdownRowListView) -> CGFloat? {
        list.cellForItem(at: IndexPath(item: item, section: 0))?.bounds.height
    }

    @Test func closeHidesOnlyTheNotice() async throws {
        let feed = PreviewFeed()
        feed.load(Self.markdown, limits: Self.limits)
        try #require(feed.store.noticeRows == [0])
        let host = Window(PreviewFeedHost(feed: feed, recorder: LineRecorder()))
        defer { host.close() }
        let list = try await host.shownList()
        try await Window.settle(list)
        let plainTextHeight = try #require(height(ofItem: 1, in: list))

        try Window.coordinator(of: list).closeNotice(0)
        try await Window.waitUntil { height(ofItem: 0, in: list) == Self.closedHeight }
        try await Window.settle(list)
        #expect(height(ofItem: 1, in: list) == plainTextHeight)
        let estimator = MarkdownRowEstimator(width: list.bounds.width, traits: list.traitCollection, theme: .default)
        #expect(try Window.coordinator(of: list).estimatedHeight(ofItem: 0, using: estimator) == Self.closedHeight)
        try Window.checkRowsAreComplete(list, "after close")
    }

    @Test func newTextShowsTheNoticeAgain() async throws {
        let feed = PreviewFeed()
        feed.load(Self.markdown, limits: Self.limits)
        let host = Window(PreviewFeedHost(feed: feed, recorder: LineRecorder()))
        defer { host.close() }
        let list = try await host.shownList()
        try await Window.settle(list)
        try Window.coordinator(of: list).closeNotice(0)
        try await Window.waitUntil { height(ofItem: 0, in: list) == Self.closedHeight }

        feed.load(Self.markdown, limits: Self.limits)
        try await Window.waitUntil { (height(ofItem: 0, in: list) ?? 0) > 0 }
    }
}
