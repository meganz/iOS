import MEGADesignToken
@testable import MEGAMarkdown
import MEGASnapshot
import SwiftUI
import Testing
import UIKit

/// `MarkdownView` at 402 wide, with the Figma content padding 16 / 8.
/// Each test records left to right, then right to left as `<test name>RightToLeft`.
@MainActor
@Suite(.serialized, .snapshot)
struct RendererSnapshotTests {
    private func assertBothDirections(
        of view: some View,
        height: CGFloat? = nil,
        dynamicType: DynamicTypeSize = .large,
        testName: String = #function,
        line: UInt = #line
    ) {
        assertSnapshot(of: view, height: height, dynamicType: dynamicType, testName: testName, line: line)
        let rightToLeftName = testName.replacingOccurrences(of: "()", with: "") + "RightToLeft"
        assertSnapshot(
            of: view, height: height, dynamicType: dynamicType, layoutDirection: .rightToLeft, testName: rightToLeftName, line: line
        )
    }

    private func assertRendered(_ markdown: String, testName: String = #function, line: UInt = #line) {
        assertBothDirections(
            of: MarkdownView(markdown).padding(.horizontal, 16).padding(.vertical, 8),
            testName: testName,
            line: line
        )
    }

    @Test func baselineAllBlocks() {
        assertBothDirections(of: MarkdownView(allBlocksMarkdown))
    }

    @Test func headings() {
        assertRendered("# Heading 1\n## Heading 2\n### Heading 3\n#### Heading 4\n##### Heading 5\n###### Heading 6")
    }

    @Test func inlineStyles() {
        assertRendered("**bold** *Italic* <u>Underline</u> ~~Strikethrough~~ ***both***")
    }

    @Test func link() {
        assertRendered("hii [google](https://www.google.com) and [www.google.com](https://www.google.com)")
    }

    @Test func inlineCode() {
        assertRendered("hii `code` and a long `inline code span that wraps onto the next line of text` end")
    }

    @Test func bulletList() {
        assertRendered("- point 1\n- point2\n  - nested\n    - third level\n- point3")
    }

    @Test func orderedList() {
        assertRendered("5. point 1\n6. point2\n7. point3")
    }

    @Test func taskList() {
        assertRendered("- [x] point1\n- [ ] point2")
    }

    @Test func quote() {
        assertRendered("> A quote with *emphasis*.\n>\n> - A list inside the quote\n>\n> > Nested quote")
    }

    @Test func codeBlock() {
        assertRendered("```swift\nlet greeting = \"Hello\"\nprint(greeting)\n```")
    }

    @Test func codeBlockLongLine() {
        assertRendered("```\nlet line = \"a very long line of code that does not wrap and scrolls sideways instead\"\n```")
    }

    @Test func table() {
        assertRendered("| Left | Center | Right |\n|:-----|:------:|------:|\n| a | b | c |\n| 1 |  | 3 |")
    }

    /// The bullet sits next to the header row, like on GitHub.
    @Test func tableInListItem() {
        assertRendered("- | A | B |\n  | --- | --- |\n  | 1 | 2 |")
    }

    @Test func codeBlockInListItem() {
        assertRendered("- ```swift\n  let a = 1\n  let b = 2\n  ```\n\n- ```\n  one\n  two\n  ```")
    }

    @Test func divider() {
        assertRendered("Above\n\n---\n\nBelow")
    }

    @Test func imageAltText() {
        assertRendered("![MEGA logo](https://mega.io/logo.png)")
    }

    /// Remote loading of a file that does not exist fails, so the alt text shows. Nothing loads from the network.
    @Test func imageRemoteFailureShowsAltText() {
        let view = MarkdownView("![MEGA logo](file:///nonexistent/logo.png)").markdownImageLoading(.remote)
        assertBothDirections(of: view.padding(.horizontal, 16).padding(.vertical, 8))
    }

    /// Images from the test bundle, like app icons a host gives with `.provided`.
    /// A wide image fits the width. A tall one stops at the theme's max height. An unknown one shows its alt text.
    @Test func imageProvided() {
        let markdown = "![Wide image](wide.png)\n\n![Tall image](tall.png)\n\n![Unknown image](unknown.png)"
        let view = MarkdownView(markdown).markdownImageLoading(.provided { url in
            Bundle.module.url(forResource: url.lastPathComponent, withExtension: nil, subdirectory: "Images")
                .flatMap { UIImage(contentsOfFile: $0.path) }
        })
        assertBothDirections(of: view.padding(.horizontal, 16).padding(.vertical, 8))
    }

    /// Blocks inside list items and quotes keep their own look and indent.
    @Test func nestedBlocks() {
        assertRendered("""
            1. First item
               ```
               code in a list
               ```
               > quote in a list
            2. Second item
               - nested bullet
                 - [x] nested task
            > Quote with a table:
            >
            > | A | B |
            > |---|---|
            > | 1 | 2 |
            """)
    }

    /// An accessibility text size: the fonts, the checkbox, inline code and the table columns grow.
    @Test func accessibilityTextSize() {
        let markdown = "# Title\n\n- [ ] Task with `code`\n- [x] Done\n\n| A | B |\n|---|---|\n| 1 | 2 |"
        assertBothDirections(of: MarkdownView(markdown).padding(16), height: 400, dynamicType: .accessibility3)
    }

    @Test func softBreakModes() {
        let source = "First line\nsecond line"
        let view = VStack(alignment: .leading, spacing: 16) {
            MarkdownView(source, softBreak: .lineBreak)
            MarkdownView(source, softBreak: .space)
        }
        assertBothDirections(of: view.padding(16))
    }

    @Test func customTheme() {
        var theme = MarkdownTheme.default
        theme.quoteBarColor = TokenColors.Text.brand.swiftUI
        assertBothDirections(of: MarkdownView("> A red quote bar").markdownTheme(theme).padding(16))
    }

    // MARK: - Split rows

    private static let listsMarkdown = """
        - Bullet one
        - Bullet two
          - Nested bullet
            - Third level

        5. Ordered five
        6. Ordered six

        - [ ] Open task
        - [x] Done task
        - Plain item
        """

    /// Lists split into one row per item, drawn by `PreviewRowView`.
    @Test func previewRowViewSplit() {
        let rows = PreviewRows.rows(for: CmarkParser.blocks(Self.listsMarkdown, softBreak: .lineBreak) ?? [], maxWeight: 0)
        let stack = VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { PreviewRowView(row: rows[$0], baseURL: nil) }
        }
        assertBothDirections(of: stack.padding(.horizontal, 16).padding(.vertical, 8))
    }

    /// Right-to-left lists split into rows: a nested item indents from the right, and the checkmark is not mirrored.
    @Test func previewRowViewRightToLeftLists() {
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
        let rows = PreviewRows.rows(for: CmarkParser.blocks(markdown, softBreak: .lineBreak) ?? [], maxWeight: 0)
        let stack = VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { PreviewRowView(row: rows[$0], baseURL: nil) }
        }
        assertBothDirections(of: stack.padding(.horizontal, 16).padding(.vertical, 8))
    }

    /// Ten quote levels: eight bars, then "…" for the hidden levels. Only the visible levels round their bar ends.
    @Test func previewRowDeepQuote() {
        let prefix = String(repeating: "> ", count: 10)
        let markdown = prefix + "First paragraph.\n" + prefix + "\n" + prefix + "Second paragraph."
        let rows = PreviewRows.rows(for: CmarkParser.blocks(markdown, softBreak: .lineBreak) ?? [], maxWeight: 0)
        let stack = VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { PreviewRowView(row: rows[$0], baseURL: nil) }
        }
        assertBothDirections(of: stack.padding(.horizontal, 16).padding(.vertical, 8))
    }

    /// Markers from "8." to "999999999.", whole and split into rows. The text starts after the marker.
    @Test func orderedListMarkerWidths() {
        let markdown = """
            8. Eight
            9. Nine
            10. Ten

            Text

            999999998. A long number with text that wraps onto the next line
            999999999. Last
            """
        let rows = PreviewRows.rows(for: CmarkParser.blocks(markdown, softBreak: .lineBreak) ?? [], maxWeight: 0)
        let view = VStack(alignment: .leading, spacing: 16) {
            MarkdownView(markdown)
            VStack(spacing: 0) {
                ForEach(rows.indices, id: \.self) { PreviewRowView(row: rows[$0], baseURL: nil) }
            }
        }
        assertBothDirections(of: view.padding(.horizontal, 16).padding(.vertical, 8))
    }
}
