import Foundation
@testable import MEGAMarkdown
import Observation
import SwiftUI
import Testing
import UIKit

/// Saves every top line the list reports.
@MainActor
final class LineRecorder {
    var lines: [Int] = []
}

/// The values a host passes to `PreviewRowList`. Tests change them, and batches arrive when a test says so.
@MainActor
@Observable
final class PreviewFeed {
    var store = PreviewRowStore()
    var generation = 0
    var rowCount = 0
    var isComplete = false
    var restoreLine: Int?
    var isShown = true
    var theme = MarkdownTheme.default
    var strings = MarkdownPreviewStrings.english
    var imageLoading = MarkdownImageLoading.altTextOnly
    var dynamicTypeSize = DynamicTypeSize.large
    var layoutDirection = LayoutDirection.leftToRight
    var colorScheme: ColorScheme?
    var openURL = OpenURLAction { _ in .systemAction }
    /// Batches of the current text that the list has not got yet.
    @ObservationIgnored private(set) var waiting: [PreviewBatch] = []

    /// Parses `markdown` and sends the first `batches` batches (all when nil).
    func load(_ markdown: String, limits: PreviewParseLimits = PreviewParseLimits(), batches: Int? = nil) {
        var parsed: [PreviewBatch] = []
        _ = PreviewPipeline.parse(MarkdownParseRequest(markdown: markdown), limits: limits) { parsed.append($0) }
        store = PreviewRowStore()
        rowCount = 0
        isComplete = false
        generation += 1
        waiting = parsed
        send(batches ?? parsed.count)
    }

    /// Sends the next `count` waiting batches. The text is complete after the last one.
    func send(_ count: Int) {
        for batch in waiting.prefix(count) {
            store.append(batch.rows)
        }
        waiting.removeFirst(min(count, waiting.count))
        rowCount = store.count
        isComplete = waiting.isEmpty
    }

    var rows: [PreviewRow] {
        (0..<store.count).map { store[$0] }
    }
}

/// `PreviewRowList` with the values of a feed, like `MarkdownPreview` passes them.
struct PreviewFeedHost: View {
    let feed: PreviewFeed
    let recorder: LineRecorder

    var body: some View {
        if feed.isShown {
            PreviewRowList(
                store: feed.store,
                generation: feed.generation,
                rowCount: feed.rowCount,
                isComplete: feed.isComplete,
                baseURL: nil,
                restoreLine: feed.restoreLine
            ) { recorder.lines.append($0) }
            .markdownTheme(feed.theme)
            .markdownPreviewStrings(feed.strings)
            .markdownImageLoading(feed.imageLoading)
            .environment(\.dynamicTypeSize, feed.dynamicTypeSize)
            .environment(\.layoutDirection, feed.layoutDirection)
            .environment(\.openURL, feed.openURL)
            .transformEnvironment(\.colorScheme) { scheme in
                if let colorScheme = feed.colorScheme { scheme = colorScheme }
            }
        } else {
            Color.clear
        }
    }
}

/// A preview list in a real window, and the checks the list tests share.
@MainActor
final class PreviewListWindow {
    static let phoneSize = CGSize(width: 402, height: 874)

    struct TimedOut: Error {}

    let window: UIWindow

    init(_ view: some View, size: CGSize = phoneSize, style: UIUserInterfaceStyle = .light) {
        window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.overrideUserInterfaceStyle = style
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
    }

    func close() {
        window.rootViewController = nil
        window.isHidden = true
    }

    /// Polls `condition` every 10 ms. Throws when it is still false after `timeout`.
    static func waitUntil(timeout: Duration = .seconds(20), _ condition: () throws -> Bool) async throws {
        let deadline = ContinuousClock.now + timeout
        while try !condition() {
            guard ContinuousClock.now < deadline else { throw TimedOut() }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    var list: MarkdownRowListView? {
        var pending: [UIView] = [window]
        while let view = pending.popLast() {
            if let list = view as? MarkdownRowListView { return list }
            pending.append(contentsOf: view.subviews)
        }
        return nil
    }

    /// The list once it shows cells.
    func shownList() async throws -> MarkdownRowListView {
        try await Self.waitUntil { list?.visibleCells.isEmpty == false }
        return try #require(list)
    }

    static func coordinator(of list: MarkdownRowListView) throws -> PreviewRowList.Coordinator {
        try #require(list.delegate as? PreviewRowList.Coordinator)
    }

    static func layout(of list: MarkdownRowListView) throws -> MarkdownRowLayout {
        try #require(list.collectionViewLayout as? MarkdownRowLayout)
    }

    /// Runs layout passes until no restore is pending, no pin holds a row, and nothing moves for 3 polls.
    static func settle(_ list: MarkdownRowListView) async throws {
        let coordinator = try coordinator(of: list)
        var last = ""
        var stablePolls = 0
        try await waitUntil {
            list.setNeedsLayout()
            list.layoutIfNeeded()
            let state = "\(list.contentOffset.y) \(list.contentSize) \(list.visibleCells.map(\.frame))"
            stablePolls = state == last ? stablePolls + 1 : 0
            last = state
            return stablePolls >= 3 && coordinator.pin == nil && coordinator.pendingJump == nil
        }
    }

    /// Visible cells in row order.
    static func visibleCells(_ list: MarkdownRowListView) -> [(item: Int, cell: UICollectionViewCell)] {
        list.indexPathsForVisibleItems.sorted().compactMap { path in
            list.cellForItem(at: path).map { (itemCount(list, sections: path.section) + path.item, $0) }
        }
    }

    /// The rows in the first `sections` sections, or in all sections when nil. Each append adds a section.
    static func itemCount(_ list: MarkdownRowListView, sections: Int? = nil) -> Int {
        (0..<(sections ?? list.numberOfSections)).reduce(0) { $0 + list.numberOfItems(inSection: $1) }
    }

    /// The first row whose cell reaches below the top edge of the list.
    static func topVisibleRow(_ list: MarkdownRowListView) -> Int? {
        let top = list.contentOffset.y + list.adjustedContentInset.top
        return visibleCells(list).first { $0.cell.frame.maxY > top + 1 }?.item
    }

    static func topVisibleLine(_ list: MarkdownRowListView) throws -> Int? {
        let coordinator = try coordinator(of: list)
        return topVisibleRow(list).map { coordinator.store[$0].sourceLine }
    }

    static func scroll(_ list: MarkdownRowListView, toRow row: Int) async throws {
        let layout = try layout(of: list)
        list.contentOffset.y = layout.heights.offset(of: row) - list.adjustedContentInset.top
        try await settle(list)
    }

    /// Every visible row shows all its content: the cell is as tall as its content, and the height list agrees.
    static func checkRowsAreComplete(_ list: MarkdownRowListView, _ label: String, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let layout = try layout(of: list)
        for (item, cell) in visibleCells(list) {
            let fitted = cell.contentView.systemLayoutSizeFitting(
                CGSize(width: cell.bounds.width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            let content = max(ceil(fitted.height), 1)
            #expect(abs(content - cell.bounds.height) <= 0.5, "\(label) row \(item): cell \(cell.bounds.height), content \(content)",
                    sourceLocation: sourceLocation)
            #expect(abs(layout.heights.height(at: item) - cell.bounds.height) <= 0.5, "\(label) row \(item): height list",
                    sourceLocation: sourceLocation)
        }
    }
}
