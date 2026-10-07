@testable import MEGAMarkdown
import MEGASnapshot
import SwiftUI
import Testing
import UIKit

/// `MarkdownPreview` in a window, 402 wide. The image is taken when every row is parsed,
/// the rows on screen have sized themselves and nothing moves any more.
/// Each test records left to right, then right to left as `<test name>RightToLeft`.
@MainActor
@Suite(.serialized, .snapshot)
struct PreviewSnapshotTests {
    private func assertBothDirections(
        of view: some View,
        height: CGFloat,
        dynamicType: DynamicTypeSize = .large,
        testName: String = #function,
        line: UInt = #line
    ) async {
        await assertHostedSnapshot(
            of: view, height: height, dynamicType: dynamicType, isReady: Self.readyCheck(), testName: testName, line: line
        )
        let rightToLeftName = testName.replacingOccurrences(of: "()", with: "") + "RightToLeft"
        await assertHostedSnapshot(
            of: view,
            height: height,
            dynamicType: dynamicType,
            layoutDirection: .rightToLeft,
            isReady: Self.readyCheck(),
            testName: rightToLeftName,
            line: line
        )
    }

    /// True once the text is complete, no restore is waiting or pinned, the visible rows are measured,
    /// and the list did not move for 3 checks in a row.
    private static func readyCheck() -> @MainActor (UIWindow) -> Bool {
        var last = ""
        var stableChecks = 0
        return { window in
            guard let list = list(in: window),
                  let coordinator = list.delegate as? PreviewRowList.Coordinator,
                  let layout = list.collectionViewLayout as? MarkdownRowLayout else { return false }
            list.setNeedsLayout()
            list.layoutIfNeeded()
            let items = list.indexPathsForVisibleItems.map(\.item).sorted()
            guard coordinator.isComplete, coordinator.pendingRestoreLine == nil, coordinator.pendingJump == nil, coordinator.pin == nil,
                  !items.isEmpty, items.allSatisfy({ layout.heights.isMeasured($0) }) else {
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

    // MARK: - Tests

    @Test func previewAllBlocks() async {
        await assertBothDirections(of: MarkdownPreview(allBlocksMarkdown), height: 1_800)
    }

    @Test func previewAccessibility() async {
        let markdown = """
            # Title

            A paragraph with `code` and a [link](https://mega.io).

            - [ ] Task
            - [x] Done

            > A quote

            | A | B |
            |---|---|
            | 1 | 2 |
            """
        await assertBothDirections(of: MarkdownPreview(markdown), height: 1_400, dynamicType: .accessibility3)
    }

    /// An open fence with no safe cut in the first 8 MB: the text shows as plain text, after a notice.
    @Test func previewNotices() async {
        let markdown = "# Notices\n\n```\n" + String(repeating: "A line inside a fence that never closes.\n", count: 220_000)
        await assertBothDirections(of: MarkdownPreview(markdown), height: 600)
    }

    /// The preview opens at line 1,000: "Paragraph 500" is the top row.
    @Test func previewRestoredMiddle() async {
        let markdown = (0..<2_000).map { "Paragraph \($0) with a few words." }.joined(separator: "\n\n")
        await assertBothDirections(of: MarkdownPreview(markdown, restoreLine: 1_000), height: 600)
    }

    /// A short code block shows every line. Its last line is not cut with "…".
    @Test func previewShortCodeBlock() async {
        let markdown = """
            ### Section 0 folder

            ```swift
            let value0 = 228 // share
            let value1 = 754 // folder
            let value2 = 692 // storage
            let value3 = 913 // encrypt
            let value4 = 89 // node
            ```

            Key account upload mega backup `video` chat.
            """
        await assertBothDirections(of: MarkdownPreview(markdown), height: 400)
    }

    /// Inline code chips keep 2 pt to the word or chip next to them.
    @Test func previewInlineCodeSpacing() async {
        let markdown = """
            ` `
            `  `

            [not a `link](/foo`)

            Two chips `a` `b` and `code`, then `x`.
            """
        await assertBothDirections(of: MarkdownPreview(markdown), height: 300)
    }

    /// Each paragraph, heading and list item takes the direction of its first strong letter.
    /// Quote bars follow the layout. Tables and code stay left to right.
    @Test func previewMixedDirections() async {
        let markdown = """
            # כותרת בעברית

            English paragraph first.

            פסקה בעברית עם **הדגשה** ו־`code`.

            - פריט ראשון
            - English item
            - [x] משימה שבוצעה

            1. מספר אחד
            2. מספר שתיים

            > ציטוט בעברית
            >
            > An English line in the quote.

            | עמודה | Column |
            |---|---|
            | א | b |

            ```
            let value = 1
            ```
            """
        await assertBothDirections(of: MarkdownPreview(markdown), height: 900)
    }

    /// Right-to-left lists: a nested item indents from the right, and the checkmark is not mirrored.
    @Test func previewRightToLeftLists() async {
        let markdown = """
            - عنصر أول
            - عنصر ثان
              - عنصر متداخل
                - עוד רמה

            1. פריט ראשון
            2. פריט שני

            - [ ] مهمة مفتوحة
            - [x] משימה שהושלמה
            """
        await assertBothDirections(of: MarkdownPreview(markdown), height: 500)
    }

    /// Host bars added with `safeAreaInset`, in a 400 pt frame away from the window edges. The restore line is past
    /// the end, so the list shows its end: "Paragraph 39" sits fully above the bottom bar. Rows scroll under the top bar.
    @Test func previewHostBars() async {
        let markdown = (0..<40).map { "Paragraph \($0) with a few words." }.joined(separator: "\n\n")
        let view = MarkdownPreview(markdown, restoreLine: 10_000)
            .safeAreaInset(edge: .top, spacing: 0) { Color.blue.opacity(0.5).frame(height: 44) }
            .safeAreaInset(edge: .bottom, spacing: 0) { Color.blue.opacity(0.5).frame(height: 25) }
            .frame(height: 400)
        await assertBothDirections(of: view, height: 600)
    }
}
