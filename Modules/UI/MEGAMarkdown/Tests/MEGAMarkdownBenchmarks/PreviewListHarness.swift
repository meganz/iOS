@testable import MEGAMarkdown
import SwiftUI
import UIKit

/// The production `PreviewRowList` in a hosting controller, with rows that are already parsed.
/// So the benchmarks measure the list the preview shows, without the parse.
/// With `batchEnds`, the list starts with the first batch and `loadNextBatch()` adds the next one, as a loading preview does.
@MainActor
final class PreviewListHarness {
    /// The rows the list reads. With `batchEnds` it holds the loaded batches only.
    let store: PreviewRowStore
    /// All rows of the document. The batches come from here.
    private let source: PreviewRowStore
    /// The view controller to show in a window.
    let rootViewController: UIViewController
    /// The row count after each parse batch. Empty means one section with every row.
    let batchEnds: [Int]
    private(set) var loadedBatches: Int
    var textSize: DynamicTypeSize = .large {
        didSet { refresh() }
    }
    var theme = MarkdownTheme.default {
        didSet { refresh() }
    }
    private let controller: UIHostingController<Root>

    init(store: PreviewRowStore, frame: CGRect, batchEnds: [Int] = []) {
        source = store
        self.batchEnds = batchEnds
        loadedBatches = batchEnds.isEmpty ? 0 : 1
        let shown = batchEnds.isEmpty ? store : PreviewRowStore(rows: (0..<batchEnds[0]).map { store[$0] })
        self.store = shown
        controller = UIHostingController(rootView: Root(
            store: shown,
            rowCount: shown.count,
            isComplete: batchEnds.count <= 1,
            textSize: .large,
            theme: .default
        ))
        controller.view.frame = frame
        rootViewController = controller
    }

    var hasMoreBatches: Bool { loadedBatches < batchEnds.count }

    /// Shows the next parse batch. The list appends it in a new section.
    func loadNextBatch() {
        guard hasMoreBatches else { return }
        let end = batchEnds[loadedBatches]
        store.append((store.count..<end).map { source[$0] })
        loadedBatches += 1
        refresh()
    }

    /// The list view inside the hosting view. It exists after the first layout pass.
    var collectionView: UICollectionView {
        Self.list(in: rootViewController.view) ?? UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    }

    /// The index path of a row. A list loaded in batches has one section per batch.
    func indexPath(ofRow index: Int) -> IndexPath {
        (collectionView.collectionViewLayout as? MarkdownRowLayout)?.indexPath(ofItem: index) ?? IndexPath(item: index, section: 0)
    }

    func scroll(toRow index: Int, at position: UICollectionView.ScrollPosition) {
        collectionView.scrollToItem(at: indexPath(ofRow: index), at: position, animated: false)
    }

    private func refresh() {
        controller.rootView = Root(
            store: store,
            rowCount: store.count,
            isComplete: batchEnds.isEmpty || loadedBatches == batchEnds.count,
            textSize: textSize,
            theme: theme
        )
    }

    static func list(in root: UIView) -> MarkdownRowListView? {
        var pending: [UIView] = [root]
        while let view = pending.popLast() {
            if let list = view as? MarkdownRowListView { return list }
            pending.append(contentsOf: view.subviews)
        }
        return nil
    }

    /// The rows the preview makes for `markdown`, parsed the way the preview parses it.
    static func store(for markdown: String) -> PreviewRowStore {
        batchedStore(for: markdown).store
    }

    /// The same rows, and the row count after each parse batch.
    static func batchedStore(for markdown: String) -> (store: PreviewRowStore, batchEnds: [Int]) {
        let store = PreviewRowStore()
        var ends: [Int] = []
        _ = PreviewPipeline.parse(MarkdownParseRequest(markdown: markdown), limits: PreviewParseLimits(), sendLineCount: { _ in }, send: {
            store.append($0.rows)
            ends.append(store.count)
        })
        return (store, ends)
    }

    private struct Root: View {
        let store: PreviewRowStore
        let rowCount: Int
        let isComplete: Bool
        let textSize: DynamicTypeSize
        let theme: MarkdownTheme

        var body: some View {
            PreviewRowList(
                store: store,
                generation: 1,
                rowCount: rowCount,
                isComplete: isComplete,
                baseURL: nil,
                restoreLine: nil,
                onReadingPositionChange: { _ in }
            )
            .environment(\.dynamicTypeSize, textSize)
            .environment(\.markdownTheme, theme)
        }
    }
}
