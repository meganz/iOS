import MEGAMarkdown
@testable import MEGAMarkdownEditor
import SwiftUI
import Testing
import UIKit

/// Rich mode of a Markdown text in a window, for layout tests that give the same result on every run.
/// A test drives the model, calls `flushLayout()` and checks the geometry, all in one synchronous call.
/// The window is visible but never the key window, so no row takes the focus and no keyboard shows.
@MainActor
final class RichLayoutHarness {
    struct HarnessError: Error, CustomStringConvertible {
        let description: String
    }

    private struct Root: View {
        let adapter: RichRowAdapter
        let layoutDirection: LayoutDirection
        let dynamicType: DynamicTypeSize

        var body: some View {
            RichEditorView(adapter: adapter, baseURL: nil)
                .environment(\.layoutDirection, layoutDirection)
                .environment(\.dynamicTypeSize, dynamicType)
        }
    }

    let adapter: RichRowAdapter
    let window: UIWindow

    var model: RichEditorModel { adapter.model }
    var list: MarkdownRowList { adapter.list }

    init(
        _ markdown: String,
        width: CGFloat = 390,
        height: CGFloat = 700,
        layoutDirection: LayoutDirection = .leftToRight,
        dynamicType: DynamicTypeSize = .large
    ) throws {
        guard case .loaded(let load) = RichEditorLoad.make(markdown) else {
            throw HarnessError(description: "The markdown did not load as a rich document")
        }
        UIView.setAnimationsEnabled(false)
        adapter = RichRowAdapter(model: RichEditorModel(editor: load.editor), load: load)
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        window.rootViewController = UIHostingController(
            rootView: Root(adapter: adapter, layoutDirection: layoutDirection, dynamicType: dynamicType)
        )
        window.isHidden = false
        flushLayout()
    }

    func close() {
        window.isHidden = true
        window.rootViewController = nil
    }

    /// The stored height of every item.
    var heights: [CGFloat] {
        (0..<list.itemCount).map { list.itemFrame(at: $0).height }
    }

    /// Runs layout passes until the stored heights and the content size stop changing.
    /// A cell that sizes itself can change the layout again, so one pass is not always enough.
    func flushLayout(sourceLocation: SourceLocation = #_sourceLocation) {
        var last: ([CGFloat], CGSize)?
        for _ in 0..<8 {
            window.layoutIfNeeded()
            list.view.layoutIfNeeded()
            let now = (heights, list.view.contentSize)
            if let last, last == now { return }
            last = now
        }
        Issue.record("The layout did not settle: \(last?.0 ?? [])", sourceLocation: sourceLocation)
    }

    /// Puts the caret in the model only. The editor does not take the focus.
    func placeCaret(row: Int, offset: Int) {
        model.select(.caret(RichPosition(blockIndex: row, offset: offset)))
    }

    /// Scrolls so that content `y` is at the top of the list, like a drag that stopped there. Stops at the end.
    /// Cells that size themselves can change the content height, so it scrolls again until the height stays.
    func scroll(toY y: CGFloat) {
        let view = list.view
        for _ in 0..<4 {
            let height = view.contentSize.height
            let top = -view.adjustedContentInset.top
            let end = max(height + view.adjustedContentInset.bottom - view.bounds.height, top)
            view.contentOffset.y = min(y + top, end)
            flushLayout()
            if view.contentSize.height == height { return }
        }
    }

    /// True when the list shows its last pixel.
    var isAtTheEnd: Bool {
        let view = list.view
        return view.contentOffset.y >= view.contentSize.height + view.adjustedContentInset.bottom - view.bounds.height - 0.5
    }
}
