@testable import MEGAMarkdown
import Observation
import SwiftUI
import Testing
import UIKit

/// `MarkdownPreview` from text to screen, with the real chunk size.
@MainActor
@Suite(.serialized, .timeLimit(.minutes(1)))
struct MarkdownPreviewTests {
    private typealias Window = PreviewListWindow

    /// About 2 MB, so the target paragraph on line 80,000 is in the second chunk.
    private static let targetLine = 80_000
    private static let twoChunkText: String = {
        let filler = { (range: Range<Int>) in range.map { "Para \($0) with some words here." } }
        return (filler(0..<40_000) + ["Target paragraph."] + filler(40_000..<60_000)).joined(separator: "\n\n")
    }()

    @Observable
    @MainActor
    final class TextSettings {
        var markdown: String
        init(markdown: String) { self.markdown = markdown }
    }

    private struct TextHost: View {
        let settings: TextSettings
        let recorder: LineRecorder

        var body: some View {
            MarkdownPreview(settings.markdown) { recorder.lines.append($0) }
        }
    }

    /// Keeps the report in SwiftUI state, like a host app that saves the reading place.
    private struct StateHost: View {
        let markdown: String
        let restoreLine: Int
        let recorder: LineRecorder
        @State private var line: Int?

        var body: some View {
            MarkdownPreview(markdown, restoreLine: restoreLine) { line = $0 }
                .onChange(of: line) { _, new in
                    if let new { recorder.lines.append(new) }
                }
        }
    }

    @Observable
    @MainActor
    final class BarHeights {
        var top: CGFloat = 40
        var bottom: CGFloat = 25
    }

    /// Host bars added with `safeAreaInset`, like a toolbar a host draws in SwiftUI.
    private struct BarHost: View {
        let markdown: String
        let bars: BarHeights

        var body: some View {
            MarkdownPreview(markdown)
                .safeAreaInset(edge: .top, spacing: 0) { Color.red.frame(height: bars.top) }
                .safeAreaInset(edge: .bottom, spacing: 0) { Color.red.frame(height: bars.bottom) }
        }
    }

    /// The width in points of the columns with ink in `window`, drawn at scale 1. Nil when nothing is drawn.
    private func inkWidth(in window: UIWindow) throws -> Int? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: window.bounds.size, format: format).image { context in
            window.layer.render(in: context.cgContext)
        }
        let cgImage = try #require(image.cgImage)
        let bytes = Array(try #require(cgImage.dataProvider?.data as Data?))
        let columns = (0..<cgImage.width).filter { x in
            (0..<cgImage.height).contains { y in bytes[y * cgImage.bytesPerRow + x * 4 + 3] > 0 }
        }
        guard let first = columns.first, let last = columns.last else { return nil }
        return last - first + 1
    }

    /// `view` in a window with a clear background, so only the drawn content has ink.
    private func clearWindow(_ view: some View) -> Window {
        let host = Window(view)
        host.window.rootViewController?.view.backgroundColor = .clear
        return host
    }

    /// The message is checked by its drawn width. A spinner is far narrower than one line of text.
    /// The accessibility tree is not used: SwiftUI builds no accessibility elements in this test process.
    @Test func textOverTheLimitShowsTheMessage() async throws {
        var strings = MarkdownPreviewStrings.english
        strings.tooLarge = "Over the limit"
        let reference = clearWindow(Text(strings.tooLarge).font(MarkdownTheme.default.bodyFont))
        defer { reference.close() }
        try await Window.waitUntil(timeout: .seconds(5)) { try inkWidth(in: reference.window) != nil }
        let expectedWidth = try inkWidth(in: reference.window)

        let markdown = String(repeating: "a", count: MarkdownPreview.sizeLimitInBytes + 1)
        let host = clearWindow(MarkdownPreview(markdown).markdownPreviewStrings(strings))
        defer { host.close() }
        try? await Window.waitUntil(timeout: .seconds(5)) { try inkWidth(in: host.window) == expectedWidth }
        #expect(try inkWidth(in: host.window) == expectedWidth)
        #expect(host.list == nil)
    }

    /// The first text shows a spinner, not a list. A new text keeps the old rows until its own rows arrive.
    @Test func spinnerShowsOnlyOnTheFirstLoad() async throws {
        let settings = TextSettings(markdown: Self.twoChunkText)
        let recorder = LineRecorder()
        let host = Window(TextHost(settings: settings, recorder: recorder))
        defer { host.close() }
        host.window.layoutIfNeeded()
        #expect(host.list == nil)
        let list = try await host.shownList()

        settings.markdown = (0..<100_000).map { "- other \($0)" }.joined(separator: "\n")
        var listStayed = true
        try await Window.waitUntil {
            listStayed = listStayed && host.list === list
            return try Window.coordinator(of: list).store.last.map { row in
                if case .textPiece(let text, _, _) = row.content { return text.text.hasPrefix("other") }
                return false
            } == true
        }
        #expect(listStayed)
        try await Window.settle(list)
        #expect(try Window.topVisibleLine(list) == 0)
    }

    /// The list runs under the host bars, but the first and last rows stay clear of them, also after a bar grows.
    @Test func hostBarsDoNotCoverTheRows() async throws {
        let bars = BarHeights()
        let markdown = (0..<60).map { "Paragraph \($0) with some words here." }.joined(separator: "\n\n")
        let host = Window(BarHost(markdown: markdown, bars: bars))
        defer { host.close() }
        let window = host.window
        let list = try await host.shownList()
        try await Window.settle(list)
        #expect(list.convert(list.bounds, to: window) == window.bounds)

        func rowFrames() -> (first: CGRect?, last: CGRect?) {
            let cells = Window.visibleCells(list)
            let count = (try? Window.coordinator(of: list).store.count) ?? 0
            let first = cells.first { $0.item == 0 }.map { $0.cell.convert($0.cell.bounds, to: window) }
            let last = cells.first { $0.item == count - 1 }.map { $0.cell.convert($0.cell.bounds, to: window) }
            return (first, last)
        }
        func scrollToEnd() async throws {
            list.contentOffset.y = list.contentSize.height + list.adjustedContentInset.bottom - list.bounds.height
            try await Window.settle(list)
            list.contentOffset.y = list.contentSize.height + list.adjustedContentInset.bottom - list.bounds.height
            try await Window.settle(list)
        }

        let topBarEnd = window.safeAreaInsets.top + bars.top
        let first = try #require(rowFrames().first)
        #expect(first.minY >= topBarEnd, "first row \(first), top bar ends at \(topBarEnd)")
        try Window.checkRowsAreComplete(list, "top")

        for bottom in [CGFloat(25), 120] {
            bars.bottom = bottom
            try await Window.waitUntil { list.contentInset.bottom >= bottom }
            try await scrollToEnd()
            let barStart = window.bounds.height - window.safeAreaInsets.bottom - bottom
            let last = try #require(rowFrames().last, "bar \(bottom)")
            #expect(last.maxY <= barStart, "bar \(bottom): last row \(last), bar starts at \(barStart)")
            try Window.checkRowsAreComplete(list, "bar \(bottom)")
        }
    }

    /// The restore line is in the second chunk. The host's state gets that line, and never line 0 first.
    @Test func restoreReportsTheTargetLineToHostState() async throws {
        let recorder = LineRecorder()
        let host = Window(StateHost(markdown: Self.twoChunkText, restoreLine: Self.targetLine, recorder: recorder))
        defer { host.close() }
        try await Window.waitUntil(timeout: .seconds(40)) { recorder.lines.last == Self.targetLine }
        let list = try #require(host.list)
        try await Window.settle(list)
        #expect(try Window.topVisibleLine(list) == Self.targetLine)
        #expect(recorder.lines == [Self.targetLine])
    }

    // MARK: - Restore with a reused view

    @Observable
    @MainActor
    final class TextAndLine {
        var markdown: String
        var restoreLine: Int?
        init(markdown: String, restoreLine: Int? = nil) {
            self.markdown = markdown
            self.restoreLine = restoreLine
        }
    }

    private struct ReusedHost: View {
        let settings: TextAndLine
        let recorder: LineRecorder

        var body: some View {
            MarkdownPreview(settings.markdown, restoreLine: settings.restoreLine) { recorder.lines.append($0) }
        }
    }

    private static func paragraphs(_ count: Int, word: String) -> String {
        (0..<count).map { "\(word) \($0) with some words here." }.joined(separator: "\n\n")
    }

    private static func firstWord(of store: PreviewRowStore) -> Substring? {
        guard let row = store.last, case .textPiece(let text, _, _) = row.content else { return nil }
        return text.text.split(separator: " ").first
    }

    /// The host shows file B in the same view and passes the saved line of B. The list must open B at that line.
    /// It must not use the line on the rows of file A, which are still on screen when the new line arrives.
    @Test func newTextWithANewRestoreLineOpensTheNewTextAtThatLine() async throws {
        let settings = TextAndLine(markdown: Self.paragraphs(20_000, word: "Alpha"))
        let recorder = LineRecorder()
        let host = Window(ReusedHost(settings: settings, recorder: recorder))
        defer { host.close() }
        let list = try await host.shownList()
        let coordinator = try Window.coordinator(of: list)
        try await Window.waitUntil { coordinator.isComplete }
        try await Window.settle(list)
        recorder.lines.removeAll()

        settings.markdown = Self.paragraphs(20_000, word: "Bravo")
        settings.restoreLine = 10_000
        try await Window.waitUntil(timeout: .seconds(40)) { Self.firstWord(of: coordinator.store) == "Bravo" && coordinator.isComplete }
        try await Window.settle(list)
        #expect(try Window.topVisibleLine(list) == 10_000)
        #expect(recorder.lines == [10_000], "reports: \(recorder.lines)")
    }

    // MARK: - Push and pop

    private final class PushedScreen: UIViewController {}

    /// A host pushes a screen while the text still parses, then pops back. The cancelled load runs again on appear.
    /// The list must keep the place of the reader.
    @Test func popAfterACancelledPartialLoadKeepsThePlace() async throws {
        let recorder = LineRecorder()
        let settings = TextAndLine(markdown: Self.paragraphs(450_000, word: "Para"))
        let navigation = UINavigationController(rootViewController: UIHostingController(rootView: ReusedHost(settings: settings, recorder: recorder)))
        let host = Window(Color.clear)
        defer { host.close() }
        host.window.rootViewController = navigation
        let list = try await host.shownList()
        let coordinator = try Window.coordinator(of: list)
        try await Window.scroll(list, toRow: 5_000)
        let line = try #require(try Window.topVisibleLine(list))
        #expect(line > 0)
        try await Window.waitUntil { recorder.lines.last == line }
        try #require(!coordinator.isComplete, "The parse ended before the push. Use a bigger text.")

        navigation.pushViewController(PushedScreen(), animated: false)
        try await Task.sleep(for: .milliseconds(300))
        try #require(!coordinator.isComplete, "The parse ended before the pop. Use a bigger text.")
        navigation.popViewController(animated: false)

        try await Window.waitUntil(timeout: .seconds(90)) { coordinator.isComplete }
        try await Window.settle(list)
        #expect(try Window.topVisibleLine(list) == line)
        #expect(!recorder.lines.dropFirst().contains(0), "reports: \(recorder.lines.prefix(10))")
    }
}
