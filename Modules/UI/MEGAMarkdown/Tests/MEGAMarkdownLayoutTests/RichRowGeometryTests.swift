import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Rich mode rows after edits and scrolls: each cell shows its own row at the height of its content.
@MainActor
struct RichRowGeometryTests {
    private static let paragraphs = (0..<80).map { "Paragraph \($0) with some words." }.joined(separator: "\n\n")

    @Test func showsEveryRowKind() throws {
        let table = "| a |\n|---|\n" + (0..<120).map { "| \($0) |" }.joined(separator: "\n")
        let harness = try RichLayoutHarness("# Title\n\nText\n\n- item\n\n> quote\n\n```\ncode\n```\n\n---\n\n" + table)
        defer { harness.close() }
        // 6 rows of one item, and a raw table of 3 pages.
        #expect(harness.model.rowCount == 7)
        #expect(harness.list.itemCount == 9)
        #expect(harness.adapter.textView(forItem: 0)?.text == "Title")
        #expect(harness.adapter.textView(forItem: 4)?.text == "code")
        #expect(harness.adapter.textView(forItem: 5) == nil)
        let problems = harness.rowProblems()
        #expect(problems.isEmpty, "\(problems)")
    }

    /// Enter at the end of the last list item adds an item. A second Enter on the empty item leaves the list.
    @Test func enterOnTheLastListItemKeepsTheRowsApart() throws {
        let harness = try RichLayoutHarness("- one\n- two\n- three, long enough to wrap over two lines on a phone screen\n\nAfter the list")
        defer { harness.close() }
        harness.placeCaret(row: 2, offset: harness.model.row(at: 2).block.length)

        harness.model.insertParagraphBreak()
        harness.flushLayout()
        #expect(harness.model.rowCount == 5)
        var problems = harness.rowProblems()
        #expect(problems.isEmpty, "after the first Enter: \(problems)")

        harness.model.insertText("a new item, long enough to wrap over two lines on a phone screen")
        harness.model.insertParagraphBreak()
        harness.model.insertParagraphBreak()
        harness.flushLayout()
        problems = harness.rowProblems()
        #expect(problems.isEmpty, "after the list ends: \(problems)")

        let live = harness.heights
        harness.adapter.reloadAll()
        harness.flushLayout()
        #expect(live == harness.heights, "live \(live), fresh \(harness.heights)")
    }

    /// A cell that scrolls away is reused for another row. Its text view must show the new row's text.
    @Test func scrollingShowsEachRowItsOwnText() throws {
        let harness = try RichLayoutHarness(Self.paragraphs, height: 400)
        defer { harness.close() }
        for step in 1...3 {
            harness.scroll(toY: CGFloat(step) * 700)
            let visible = harness.list.view.indexPathsForVisibleItems.map(\.item)
            #expect(visible.max() ?? 0 >= step * 5, "the list did not scroll")
            let problems = harness.rowProblems()
            #expect(problems.isEmpty, "step \(step): \(problems)")
        }
    }

    /// A paste that adds rows changes the model before the list update. Cells that UIKit makes in that gap,
    /// for example prefetched cells below the screen, must still show their own row at their own height.
    @Test func scrollingAfterAPasteThatAddsRowsShowsEachRowItsOwnTextAndHeight() throws {
        let markdown = """
        # A long title that wraps over two lines on a phone

        > **A quote** with a list:
        >
        > 1. The first step of the quote, long enough to wrap over two lines.
        > 2. The second step of the quote, long enough to wrap over two lines.

        ## A heading

        A paragraph before the list.

        - Bullet one
        - Bullet two
          - Nested bullet

        1. Ordered one
        2. Ordered two

        - [ ] Open task
        - [x] Done task

        > A quote with *emphasis*.

        ---

        ### Another heading

        A paragraph after the divider.
        """
        let harness = try RichLayoutHarness(markdown)
        defer { harness.close() }
        let row = try #require((0..<harness.model.rowCount).first { harness.model.row(at: $0).block.plainText == "A paragraph before the list." })
        harness.placeCaret(row: row, offset: 2)
        // A scroll without a layout pass: the update's first pass makes the cells below the old screen.
        harness.list.view.contentOffset.y += 300
        harness.model.paste(RichPasteContent(markdown: "- [ ] Pasted A\n- [x] Pasted B\n- Bullet C\n"))
        harness.flushLayout()
        for step in 0..<8 {
            harness.scroll(toY: CGFloat(step) * 120)
            let problems = harness.rowProblems()
            #expect(problems.isEmpty, "step \(step): \(problems)")
        }
    }

    /// Every row has the same model version. A reused cell must take its new row's text before it measures itself.
    /// Else a long row keeps the height of the short row the cell showed before.
    @Test func fastScrollToTheEndGivesReusedCellsTheHeightOfTheirOwnText() throws {
        let long = "A long task item that wraps over several lines on a phone screen, so its row is much taller than one line."
        let short = (0..<30).map { "Paragraph \($0)\n\n- Bullet \($0)\n- [ ] Task \($0)" }.joined(separator: "\n\n")
        let markdown = short + "\n\n" + (0..<4).map { "- [x] \($0) \(long)" }.joined(separator: "\n")
        let harness = try RichLayoutHarness(markdown)
        defer { harness.close() }
        var y: CGFloat = 0
        while !harness.isAtTheEnd {
            y += 900
            // One layout pass per jump, like frames of a fling. The full flush runs at the end.
            harness.list.view.contentOffset.y = y
            harness.list.view.layoutIfNeeded()
            if y > harness.list.view.contentSize.height { break }
        }
        harness.scroll(toY: .greatestFiniteMagnitude)
        #expect(harness.isAtTheEnd)
        let problems = harness.rowProblems()
        #expect(problems.isEmpty, "\(problems)")
    }

    @Test func checkboxTapTogglesTheTask() throws {
        let harness = try RichLayoutHarness("- [ ] task")
        defer { harness.close() }
        harness.model.toggleCheckbox(inRow: 0)
        harness.flushLayout()
        #expect(harness.model.row(at: 0).block == .listItem(RichListItem(isOrdered: false, isChecked: true), text: RichText("task")))
        guard case .listItem(.checkbox(isChecked: true), _)? = harness.adapter.chrome[0].decorations.first else {
            Issue.record("the chrome did not follow: \(harness.adapter.chrome[0])")
            return
        }
    }
}
