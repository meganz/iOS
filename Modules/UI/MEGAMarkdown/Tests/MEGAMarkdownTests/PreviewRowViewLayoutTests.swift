@testable import MEGAMarkdown
import SwiftUI
import Testing
import UIKit

/// Split rows must look like the whole block: a stack of split rows has the height of the whole block.
@MainActor
@Suite(.serialized) struct PreviewRowViewLayoutTests {
    private static let width: CGFloat = 390

    nonisolated private static let containers = [
        "- one\n- two\n- three\n  - nested a\n  - nested b\n- four",
        "1. one\n2. two\n\n   second paragraph\n3. three",
        "- [x] done\n- [ ] open\n- [x] done again",
        "- [ ] task\n- plain\n- [x] task",
        "> quote one\n>\n> quote two\n>\n> - item\n> - item",
        "> outer\n>\n> > inner\n> >\n> > inner two",
        "- [ ] one\n- [ ] \n- [x] three"
    ]

    private func height(of view: some View, dynamicTypeSize: DynamicTypeSize = .large) -> CGFloat {
        let controller = UIHostingController(rootView: view.frame(width: Self.width).environment(\.dynamicTypeSize, dynamicTypeSize))
        return controller.sizeThatFits(in: CGSize(width: Self.width, height: .greatestFiniteMagnitude)).height
    }

    /// The same block drawn whole (one row) and split into rows.
    private func heights(_ markdown: String, dynamicTypeSize: DynamicTypeSize = .large) -> (whole: CGFloat, split: CGFloat, rowCount: Int) {
        let blocks = CmarkParser.blocks(markdown, softBreak: .lineBreak) ?? []
        let whole = PreviewRows.rows(for: blocks)
        let split = PreviewRows.rows(for: blocks, maxWeight: 0)
        let stack = { (rows: [PreviewRow]) in
            VStack(alignment: .leading, spacing: 0) {
                ForEach(rows.indices, id: \.self) { PreviewRowView(row: rows[$0], baseURL: nil) }
            }
        }
        return (height(of: stack(whole), dynamicTypeSize: dynamicTypeSize), height(of: stack(split), dynamicTypeSize: dynamicTypeSize), split.count)
    }

    @Test(arguments: containers)
    func splitContainerHasTheSameHeight(markdown: String) {
        let result = heights(markdown)
        #expect(result.rowCount > 1)
        #expect(result.whole == result.split, "whole \(result.whole), split \(result.split)")
    }

    /// At the largest text sizes a split list must still match the whole list.
    @Test(arguments: containers)
    func splitContainerHasTheSameHeightAtAccessibilitySize(markdown: String) {
        let result = heights(markdown, dynamicTypeSize: .accessibility3)
        #expect(result.rowCount > 1)
        #expect(result.whole == result.split, "whole \(result.whole), split \(result.split)")
    }

    /// The 3 pages are one pixel (1/3 point) shorter than the whole table at 3x. So the check allows under 1 point.
    @Test func splitTableHasTheSameHeight() {
        let markdown = "| a | b |\n|---|---|\n" + (0..<120).map { "| \($0) | x |" }.joined(separator: "\n")
        let result = heights(markdown)
        #expect(result.rowCount == 3)
        #expect(abs(result.whole - result.split) < 1, "whole \(result.whole), split \(result.split)")
    }

    /// A long paragraph with line breaks is cut after a newline. The seams add no empty line, so the pieces
    /// stack to the height of the whole paragraph.
    @Test func paragraphPiecesCutAtNewlinesHaveTheSameHeight() {
        let markdown = (0..<160).map { "Line \(String(format: "%05d", $0)) with some words in it, a little longer." }.joined(separator: "\n")
        let result = heights(markdown)
        #expect(result.rowCount > 1)
        #expect(abs(result.whole - result.split) < 1, "whole \(result.whole), split \(result.split)")
    }

    /// List numbers use digits of one width, so the marker grows with the digit count only.
    /// "999999999." is the widest marker: cmark reads at most 9 digits.
    @Test func numberMarkerGrowsWithItsDigits() {
        let widths = [1, 9, 10, 99, 100, 999_999_999].map { number in
            UIHostingController(rootView: ListMarkerView(marker: .number(number), label: ""))
                .sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)).width
        }
        #expect(widths[0] == widths[1])
        #expect(widths[2] == widths[3])
        #expect(widths[1] < widths[2])
        #expect(widths[3] < widths[4])
        #expect(widths[4] < widths[5])
    }

    /// The chrome view draws a plain SwiftUI content like the preview row draws its own content.
    /// A tappable checkbox has the same size as a display-only one.
    @Test func chromeViewWithPlainContentMatchesThePreviewRow() throws {
        let rows = PreviewRows.rows(for: CmarkParser.blocks("- [ ] Task\n- [x] Done", softBreak: .lineBreak) ?? [], maxWeight: 0)
        try #require(rows.count == 2)
        let theme = MarkdownTheme.default
        for row in rows {
            let preview = height(of: PreviewRowView(row: row, baseURL: nil))
            let plain = height(of: MarkdownRowChromeView(chrome: row.chrome, checkboxLabel: row.checkboxLabel) {
                Text(row.checkboxLabel).font(theme.bodyFont)
            })
            let tappable = height(of: MarkdownRowChromeView(
                chrome: row.chrome,
                checkboxLabel: row.checkboxLabel,
                onToggle: {},
                content: { Text(row.checkboxLabel).font(theme.bodyFont) }
            ))
            #expect(plain == preview)
            #expect(tappable == preview)
        }
    }

    /// An HTML block row is as tall as a one-line paragraph, also in a quote. Its line end draws no empty line.
    @Test(arguments: ["<!-- -->", "> <div>x</div>"])
    func htmlBlockRowHasNoEmptyLine(markdown: String) throws {
        let paragraph = markdown.hasPrefix(">") ? "> x" : "x"
        let rowHeight = { (text: String) throws -> CGFloat in
            let rows = PreviewRows.rows(forMarkdown: text, softBreak: .lineBreak)
            let row = try #require(rows.first)
            #expect(rows.count == 1)
            return self.height(of: PreviewRowView(row: row, baseURL: nil))
        }
        #expect(try rowHeight(markdown) == rowHeight(paragraph))
    }

    /// A list marker lines up with the first code line, so an item that starts with code is as tall as the code box.
    @Test(arguments: ["1.     indented code", "- ```\n  fenced code\n  ```"])
    func markerOfAnItemThatStartsWithCodeStaysInTheBox(markdown: String) throws {
        let rows = PreviewRows.rows(forMarkdown: markdown, softBreak: .lineBreak)
        let item = try #require(rows.first)
        let code = try #require(PreviewRows.rows(forMarkdown: "    code", softBreak: .lineBreak).first)
        #expect(rows.count == 1)
        #expect(height(of: PreviewRowView(row: item, baseURL: nil)) == height(of: PreviewRowView(row: code, baseURL: nil)))
    }

    private static let windowSize = CGSize(width: 402, height: 874)

    private struct TimedOut: Error {}

    /// Polls `condition` every 10 ms. Throws when it is still false after `timeout`.
    private static func waitUntil(timeout: Duration, _ condition: () throws -> Bool) async throws {
        let deadline = ContinuousClock.now + timeout
        while try !condition() {
            guard ContinuousClock.now < deadline else { throw TimedOut() }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    /// `view` drawn in `size` at the top of a window, at scale 1. Premultiplied RGBA or BGRA, 4 bytes per pixel.
    /// SwiftUI draws after the layout pass, so it polls until the window has any ink.
    private func pixels(of view: some View, size: CGSize) async throws -> (bytes: [UInt8], bytesPerRow: Int) {
        let window = UIWindow(frame: CGRect(origin: .zero, size: Self.windowSize))
        // The test window has a safe area. The row must start at the window's top edge.
        let root = VStack(spacing: 0) {
            view.frame(width: size.width, height: size.height, alignment: .top)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ignoresSafeArea()
        let controller = UIHostingController(rootView: root)
        controller.view.backgroundColor = .clear
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        var result: (bytes: [UInt8], bytesPerRow: Int) = ([], 0)
        try await Self.waitUntil(timeout: .seconds(5)) {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = false
            let image = UIGraphicsImageRenderer(size: Self.windowSize, format: format).image { context in
                window.layer.render(in: context.cgContext)
            }
            let cgImage = try #require(image.cgImage)
            let data = try #require(cgImage.dataProvider?.data as Data?)
            result = (Array(data), cgImage.bytesPerRow)
            return (0..<Int(size.height)).contains { y in (0..<Int(size.width)).contains { x in result.bytes[y * result.bytesPerRow + x * 4 + 3] > 0 } }
        }
        return result
    }

    /// The alpha of the pixels at `points` of `view`, drawn in `size`.
    private func alphas(of view: some View, size: CGSize, at points: [CGPoint]) async throws -> [UInt8] {
        let image = try await pixels(of: view, size: size)
        return points.map { image.bytes[Int($0.y) * image.bytesPerRow + Int($0.x) * 4 + 3] }
    }

    /// The leftmost and rightmost columns with ink.
    private func inkColumns(of view: some View, size: CGSize) async throws -> ClosedRange<Int> {
        let image = try await pixels(of: view, size: size)
        let columns = (0..<Int(size.width)).filter { x in
            (0..<Int(size.height)).contains { y in image.bytes[y * image.bytesPerRow + x * 4 + 3] > 0 }
        }
        return try #require(columns.min()) ... (columns.max() ?? 0)
    }

    /// A nested item in a right-to-left list sits one marker column further in from the right, like its parent's text.
    @Test func nestedRightToLeftItemIsIndented() async throws {
        let rows = PreviewRows.rows(forMarkdown: "- عنصر ثان\n  - عنصر متداخل", softBreak: .lineBreak)
        try #require(rows.count == 2)
        let size = { (row: PreviewRow) in CGSize(width: Self.width, height: ceil(self.height(of: PreviewRowView(row: row, baseURL: nil)))) }
        let parent = try await inkColumns(of: PreviewRowView(row: rows[0], baseURL: nil), size: size(rows[0]))
        let nested = try await inkColumns(of: PreviewRowView(row: rows[1], baseURL: nil), size: size(rows[1]))
        #expect(nested.upperBound < parent.upperBound - 10, "parent ink ends at \(parent.upperBound), nested at \(nested.upperBound)")
    }

    /// A checkmark is not mirrored in a right-to-left row. It draws the same pixels as in a left-to-right layout.
    @Test func checkmarkIsNotMirroredInARightToLeftRow() async throws {
        let size = CGSize(width: 40, height: 40)
        let box = MarkdownCheckbox(isChecked: true).frame(width: 40, height: 40)
        let leftToRight = try await pixels(of: box, size: size)
        let rightToLeft = try await pixels(of: box.environment(\.layoutDirection, .rightToLeft), size: size)
        let region = { (image: (bytes: [UInt8], bytesPerRow: Int)) in
            (0..<40).flatMap { y in image.bytes[(y * image.bytesPerRow)..<(y * image.bytesPerRow + 40 * 4)] }
        }
        #expect(region(leftToRight) == region(rightToLeft))
    }

    /// A quote that goes on in the next row draws its bar down to the cell's bottom edge, gap and rounding included.
    /// The quote's last row stops the bar at its content.
    @Test func quoteBarReachesTheRowBottomOnlyWhenTheQuoteGoesOn() async throws {
        let rows = PreviewRows.rows(forMarkdown: "> # Foo\n> bar", softBreak: .lineBreak)
        try #require(rows.count == 2)
        for (index, row) in rows.enumerated() {
            let view = PreviewRowView(row: row, baseURL: nil)
            // One more point, like a cell whose height is rounded up.
            let size = CGSize(width: Self.width, height: ceil(height(of: view)) + 1)
            let values = try await alphas(of: view, size: size, at: [CGPoint(x: 1, y: 10), CGPoint(x: 1, y: size.height - 1)])
            if index == 0 {
                #expect(values[1] > 0, "first row: the bar reaches the bottom edge")
            } else {
                #expect(values[1] == 0, "last row: no bar below the content")
            }
        }
    }
}
