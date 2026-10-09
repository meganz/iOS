@testable import MEGAMarkdown
import MEGASnapshot
import SwiftUI
import Testing
import UIKit

/// `MarkdownPreview` with whole blocks selected, 402 wide: the system highlight and handles over a paragraph, a list
/// item, a divider and a code block, and a Hebrew row. Records `<test>` and `<test>RightToLeft`, light and dark.
@MainActor
@Suite(.serialized, .snapshot)
struct PreviewSelectionSnapshotTests {
    private static let markdown = """
    A first paragraph that is not selected.

    A second paragraph with **bold** text.

    - An item in a list

    ---

    ```
    let value = 42
    ```

    שורה בעברית

    The last paragraph, not selected.
    """

    @Test func previewSelection() async {
        for direction in [LayoutDirection.leftToRight, .rightToLeft] {
            await assertHostedSnapshot(
                of: MarkdownPreview(Self.markdown),
                height: 520,
                layoutDirection: direction,
                isReady: Self.readyCheck(),
                testName: direction == .leftToRight ? "previewSelection" : "previewSelectionRightToLeft"
            )
        }
    }

    /// Selects rows 1 to 5 once the text is complete (no edit menu), then waits until the display is on and nothing moves.
    private static func readyCheck() -> @MainActor (UIWindow) -> Bool {
        var last = ""
        var stableChecks = 0
        return { window in
            guard let list = list(in: window),
                  let coordinator = list.delegate as? PreviewRowList.Coordinator,
                  let layout = list.collectionViewLayout as? MarkdownRowLayout,
                  coordinator.isComplete, coordinator.store.count >= 7 else { return false }
            if coordinator.selection.selection == nil {
                coordinator.selection.selection = PreviewSelection(anchorRow: 1, headRow: 5)
            }
            list.setNeedsLayout()
            list.layoutIfNeeded()
            let items = list.indexPathsForVisibleItems.map(\.item).sorted()
            guard coordinator.selection.isDisplayActive, !items.isEmpty, items.allSatisfy({ layout.heights.isMeasured($0) }) else {
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
