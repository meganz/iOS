import MEGAMarkdown
@testable import MEGAMarkdownEditor
import SwiftUI
import Testing
import UIKit

/// Rows of a small Markdown string, shown read-only with the preview's row view from another target.
@MainActor
@Suite struct RawRowRenderingTests {
    private static let width: CGFloat = 390

    private func height(of view: some View) -> CGFloat {
        let controller = UIHostingController(rootView: view.frame(width: Self.width))
        return controller.sizeThatFits(in: CGSize(width: Self.width, height: .greatestFiniteMagnitude)).height
    }

    private static let bigTable = "| a | b |\n|---|---|\n" + (0..<300).map { "| \($0) | x |" }.joined(separator: "\n")

    /// The preview's row weight splits every block, so a short heading and paragraph are one text piece each.
    @Test func smallBlocksAreOneRowEach() {
        let rows = PreviewRows.rows(forMarkdown: "# Title\n\nSome text.", softBreak: .lineBreak)
        #expect(rows.count == 2)
        #expect(rows.allSatisfy { if case .textPiece(_, _, isFirst: true) = $0.content { true } else { false } })
    }

    /// 300 rows of 2 columns are over the row weight limit, so they become pages of 50 rows.
    @Test func bigTableIsSplitIntoPages() {
        let rows = PreviewRows.rows(forMarkdown: Self.bigTable, softBreak: .lineBreak)
        #expect(rows.count == 6)
        #expect(rows.allSatisfy { if case .tablePage = $0.content { true } else { false } })
    }

    /// Each page of a split table can sit in its own item of a list. Shown one by one, the pages
    /// are as tall as the same pages stacked in one view.
    @Test func eachRowRendersAlone() {
        let rows = PreviewRows.rows(forMarkdown: Self.bigTable, softBreak: .lineBreak)
        let alone = rows.map { height(of: PreviewRowView(row: $0, baseURL: nil)) }
        let stacked = height(of: VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { PreviewRowView(row: rows[$0], baseURL: nil) }
        })
        // Every page has 50 one-line rows, so the pages are equally tall. The first page also has the header row.
        #expect(alone.count == 6)
        #expect(alone[1] > 0)
        #expect(alone.dropFirst().allSatisfy { $0 == alone[1] }, "\(alone)")
        #expect(alone[0] > alone[1])
        #expect(alone.reduce(0, +) == stacked)
    }

    /// A raw table shown alone resolves `[a][r]` with the definitions of the other raw blocks of the file.
    @Test func rawTableUsesTheDefinitionsOfTheFile() throws {
        let document = RichMarkdownConverter.document(from: "| A |\n|---|\n| [a][r] |\n\n[r]: https://mega.nz\n")
        let table = try #require(document.blocks.lazy.compactMap { block -> String? in
            guard case .rawSource(let source) = block, source.hasPrefix("|") else { return nil }
            return source
        }.first)
        let rows = PreviewRows.rows(forMarkdown: table, softBreak: .lineBreak, definitions: document.referenceDefinitionSource)
        let row = try #require(rows.first)
        guard case .tablePage(let parsed, _, _, _) = row.content else {
            Issue.record("not a table row: \(row.content)")
            return
        }
        let cell = try #require(parsed.rows.first?.first)
        #expect(cell.text == "a")
        #expect(cell.links.map(\.url) == ["https://mega.nz"])
    }
}
