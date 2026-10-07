import MEGADesignToken
@testable import MEGAMarkdown
import SwiftUI
import Testing
import UIKit

/// The preview list in a real window: traits and environment values that reach the hosted rows.
@MainActor
@Suite(.serialized, .timeLimit(.minutes(1)))
struct PreviewRowListTests {
    private typealias Window = PreviewListWindow

    private static let paragraphs = (0..<2_000).map { "Paragraph \($0) with a few words." }.joined(separator: "\n\n")
    private static let mixedText = "Para text.\n\n> Quote text\n\n| a | b |\n|---|---|\n| 1 | 2 |"

    private struct Opened {
        let host: Window
        let feed: PreviewFeed
        let list: MarkdownRowListView
    }

    private func open(
        _ markdown: String,
        size: CGSize = Window.phoneSize,
        style: UIUserInterfaceStyle = .light,
        configure: (PreviewFeed) -> Void = { _ in }
    ) async throws -> Opened {
        let feed = PreviewFeed()
        configure(feed)
        feed.load(markdown)
        let host = Window(PreviewFeedHost(feed: feed, recorder: LineRecorder()), size: size, style: style)
        let list = try await host.shownList()
        try await Window.settle(list)
        return Opened(host: host, feed: feed, list: list)
    }

    // MARK: - Traits

    @Test func textSizeChangeKeepsTheTopRow() async throws {
        let opened = try await open(Self.paragraphs)
        defer { opened.host.close() }
        let list = opened.list
        try await Window.scroll(list, toRow: 500)
        let line = try #require(try Window.topVisibleLine(list))
        #expect(line == 1_000)

        opened.feed.dynamicTypeSize = .accessibility2
        try await Window.waitUntil {
            let cells = Window.visibleCells(list).map(\.cell)
            return !cells.isEmpty && cells.allSatisfy { $0.traitCollection.preferredContentSizeCategory == UIContentSizeCategory(.accessibility2) }
        }
        try await Window.settle(list)
        #expect(try Window.topVisibleLine(list) == line)
        try Window.checkRowsAreComplete(list, "after text size change")
    }

    private func styles(_ list: MarkdownRowListView) -> Set<UIUserInterfaceStyle> {
        Set(Window.visibleCells(list).map(\.cell.traitCollection.userInterfaceStyle))
    }

    @Test func colorSchemeReachesHostedRows() async throws {
        // A dark window, then light. SwiftUI hands the new scheme to the list in its next update.
        let dark = try await open(Self.mixedText, style: .dark)
        #expect(styles(dark.list) == [.dark])
        dark.host.window.overrideUserInterfaceStyle = .light
        try await Window.waitUntil { styles(dark.list) == [.light] }
        dark.host.close()

        // A dark SwiftUI subtree in a light window.
        let subtree = try await open(Self.mixedText) { $0.colorScheme = .dark }
        #expect(styles(subtree.list) == [.dark])
        subtree.host.close()

        // A light SwiftUI subtree in a dark window.
        let lightSubtree = try await open(Self.mixedText, style: .dark) { $0.colorScheme = .light }
        #expect(styles(lightSubtree.list) == [.light])
        lightSubtree.host.close()
    }

    @Test func layoutDirectionReachesHostedRows() async throws {
        let rightToLeft = try await open("- Bullet item\n\n" + Self.mixedText) { $0.layoutDirection = .rightToLeft }
        let directions = Set(Window.visibleCells(rightToLeft.list).map(\.cell.traitCollection.layoutDirection))
        #expect(directions == [.rightToLeft])
        rightToLeft.host.close()

        let leftToRight = try await open("- Bullet item\n\n" + Self.mixedText)
        #expect(Set(Window.visibleCells(leftToRight.list).map(\.cell.traitCollection.layoutDirection)) == [.leftToRight])
        leftToRight.host.close()
    }

    /// A table and a code block scroll sideways in their own scroll views. Only the list takes the status bar tap.
    @Test func onlyTheListScrollsToTop() async throws {
        let markdown = "```\n" + String(repeating: "wide code ", count: 40) + "\n```\n\n| a | b |\n|---|---|\n| 1 | 2 |\n\nEnd."
        let opened = try await open(markdown)
        defer { opened.host.close() }
        let list = opened.list
        func innerScrollViews() -> [UIScrollView] {
            var result: [UIScrollView] = []
            var pending = list.visibleCells.map(\.contentView)
            while let view = pending.popLast() {
                if let scrollView = view as? UIScrollView { result.append(scrollView) }
                pending.append(contentsOf: view.subviews)
            }
            return result
        }
        try await Window.waitUntil { innerScrollViews().count >= 2 }
        #expect(list.scrollsToTop)
        for scrollView in innerScrollViews() {
            #expect(!scrollView.scrollsToTop, "\(type(of: scrollView)) takes the status bar tap")
        }
    }

    @Test func rowsSpanTheListWidth() async throws {
        let opened = try await open(Self.mixedText + "\n\n```\n" + String(repeating: "x", count: 400) + "\n```")
        defer { opened.host.close() }
        let list = opened.list
        #expect(list.bounds.width == Window.phoneSize.width)
        #expect(list.contentSize.width == list.bounds.width)
        for (item, cell) in Window.visibleCells(list) {
            #expect(cell.frame.minX == 0 && cell.frame.width == list.bounds.width, "row \(item) frame \(cell.frame)")
        }
    }

    // MARK: - Environment values

    /// More block spacing makes each paragraph row taller by the difference. The top row stays.
    @Test func themeChangeReachesVisibleRows() async throws {
        let opened = try await open(Self.paragraphs)
        defer { opened.host.close() }
        let list = opened.list
        try await Window.scroll(list, toRow: 500)
        let line = try Window.topVisibleLine(list)
        let before = Dictionary(uniqueKeysWithValues: Window.visibleCells(list).map { ($0.item, $0.cell.bounds.height) })

        var theme = MarkdownTheme.default
        theme.blockSpacing = MarkdownTheme.default.blockSpacing + 10
        opened.feed.theme = theme
        try await Window.waitUntil {
            Window.visibleCells(list).contains { item, cell in before[item].map { cell.bounds.height == $0 + 10 } == true }
        }
        try await Window.settle(list)
        #expect(try Window.topVisibleLine(list) == line)
        for (item, cell) in Window.visibleCells(list) {
            guard let old = before[item] else { continue }
            #expect(cell.bounds.height == old + 10, "row \(item)")
        }
        try Window.checkRowsAreComplete(list, "after theme change")
    }

    /// A notice row shows the host's text, so a much longer text makes it taller.
    @Test func stringsChangeReachesVisibleRows() async throws {
        let markdown = "```\n" + String(repeating: "code line\n", count: 2_000) + "```\n"
        let feed = PreviewFeed()
        feed.load(markdown, limits: PreviewParseLimits(targetChunkBytes: 1, maxChunkBytes: 1_000))
        try #require(feed.store.noticeRows == [0])
        let host = Window(PreviewFeedHost(feed: feed, recorder: LineRecorder()))
        defer { host.close() }
        let list = try await host.shownList()
        try await Window.settle(list)
        let notice = try #require(list.cellForItem(at: IndexPath(item: 0, section: 0)))
        let before = notice.bounds.height

        var strings = MarkdownPreviewStrings.english
        strings.shownAsPlainText = String(repeating: "A long notice text. ", count: 20)
        feed.strings = strings
        try await Window.waitUntil { (list.cellForItem(at: IndexPath(item: 0, section: 0))?.bounds.height ?? 0) > before + 50 }
        try await Window.settle(list)
        try Window.checkRowsAreComplete(list, "after strings change")
    }

    /// SwiftUI sends an image policy change and a new batch in one list update when both happen in one
    /// main-actor turn. The visible image row must still get the image: it ends as tall as in a list that
    /// had the policy from the start.
    @Test func imagePolicyChangeWithABatchReachesVisibleRows() async throws {
        let markdown = "![image](https://example.com/picture.png)\n\n" + (0..<40).map { "Paragraph \($0)." }.joined(separator: "\n\n")
        let limits = PreviewParseLimits(targetChunkBytes: 1, maxChunkBytes: 1_000)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 200)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 200))
        }
        let provided = MarkdownImageLoading.provided { _ in image }

        let reference = PreviewFeed()
        reference.imageLoading = provided
        reference.load(markdown, limits: limits)
        let referenceHost = Window(PreviewFeedHost(feed: reference, recorder: LineRecorder()))
        defer { referenceHost.close() }
        let referenceList = try await referenceHost.shownList()
        try await Window.settle(referenceList)
        let expected = try #require(referenceList.cellForItem(at: IndexPath(item: 0, section: 0))).bounds.height

        // The first batch can be empty with a 1-byte chunk target, so three batches go first.
        let feed = PreviewFeed()
        feed.load(markdown, limits: limits, batches: 3)
        try #require(!feed.waiting.isEmpty)
        let host = Window(PreviewFeedHost(feed: feed, recorder: LineRecorder()))
        defer { host.close() }
        let list = try await host.shownList()
        try await Window.settle(list)
        let countBefore = Window.itemCount(list)
        let altTextHeight = try #require(list.cellForItem(at: IndexPath(item: 0, section: 0))).bounds.height
        try #require(altTextHeight != expected)

        feed.imageLoading = provided
        feed.send(1)
        try await Window.waitUntil(timeout: .seconds(2)) { list.cellForItem(at: IndexPath(item: 0, section: 0))?.bounds.height == expected }
        try await Window.settle(list)
        #expect(Window.itemCount(list) > countBefore)
        #expect(list.cellForItem(at: IndexPath(item: 0, section: 0))?.bounds.height == expected)
        try Window.checkRowsAreComplete(list, "after image policy change with a batch")
    }

    @MainActor private final class URLRecorder {
        var urls: [String] = []
    }

    /// Rows call the coordinator's action, and it calls the host's current handler.
    @Test func openURLChangeReachesTheRows() async throws {
        let recorder = URLRecorder()
        let opened = try await open("Read [the docs](https://mega.io/docs) now.") { feed in
            feed.openURL = OpenURLAction { url in
                recorder.urls.append("first \(url.absoluteString)")
                return .handled
            }
        }
        defer { opened.host.close() }
        let coordinator = try Window.coordinator(of: opened.list)
        let url = try #require(URL(string: "https://mega.io/docs"))
        coordinator.forwardingOpenURL(url)

        opened.feed.openURL = OpenURLAction { url in
            recorder.urls.append("second \(url.absoluteString)")
            return .handled
        }
        try await Window.settle(opened.list)
        coordinator.forwardingOpenURL(url)
        #expect(recorder.urls == ["first https://mega.io/docs", "second https://mega.io/docs"])
    }
}
