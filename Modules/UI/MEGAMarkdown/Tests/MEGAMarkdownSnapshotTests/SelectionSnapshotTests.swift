@testable import MEGAMarkdown
@testable import MEGAMarkdownEditor
import MEGASnapshot
import SwiftUI
import Testing
import UIKit

/// A selection over rows, 402 wide, over text, a divider and a Hebrew row. Records `<test>` and `<test>RightToLeft`.
/// Direction and color scheme come only from the SwiftUI environment.
@MainActor
@Suite(.serialized, .snapshot)
struct SelectionSnapshotTests {
    private static let markdown = """
    A first paragraph with some words.

    ---

    A second paragraph.

    - An item in a list

    שורה בעברית
    """

    /// From the middle of the first paragraph to the middle of the Hebrew row, over the divider.
    private static let selection = RichSelection(
        start: RichPosition(blockIndex: 0, offset: 8),
        end: RichPosition(blockIndex: 4, offset: 4)
    )

    @Test func selectionOverRows() async throws {
        for direction in [LayoutDirection.leftToRight, .rightToLeft] {
            let view = try Self.editor()
            await assertHostedSnapshot(
                of: view,
                height: 420,
                layoutDirection: direction,
                isReady: Self.readyCheck(),
                testName: direction == .leftToRight ? "selectionOverRows" : "selectionOverRowsRightToLeft"
            )
        }
    }

    /// A new rich editor with the selection already in the model. Not focused, so no keyboard shows.
    private static func editor() throws -> some View {
        guard case .loaded(let load) = RichEditorLoad.make(markdown) else { throw CancellationError() }
        let model = RichEditorModel(editor: load.editor)
        model.select(selection)
        return RichEditorView(adapter: RichRowAdapter(model: model, load: load), baseURL: nil)
    }

    /// True once the rows are measured, the selection display is on, and nothing moved for 3 checks in a row.
    private static func readyCheck() -> @MainActor (UIWindow) -> Bool {
        var last = ""
        var stableChecks = 0
        return { window in
            guard let list = list(in: window), let layout = list.collectionViewLayout as? MarkdownRowLayout,
                  list.interactions.contains(where: { ($0 as? UITextSelectionDisplayInteraction)?.isActivated == true }) else {
                return false
            }
            list.setNeedsLayout()
            list.layoutIfNeeded()
            let items = list.indexPathsForVisibleItems.map(\.item).sorted()
            guard !items.isEmpty, items.allSatisfy({ layout.heights.isMeasured($0) }) else {
                stableChecks = 0
                return false
            }
            let state = "\(list.contentOffset.y) \(list.contentSize) \(items)"
            stableChecks = state == last ? stableChecks + 1 : 0
            last = state
            return stableChecks >= 3
        }
    }

    private static func list(in window: UIWindow) -> MarkdownRowListView? {
        var pending: [UIView] = [window]
        while let view = pending.popLast() {
            if let list = view as? MarkdownRowListView { return list }
            pending.append(contentsOf: view.subviews)
        }
        return nil
    }
}
