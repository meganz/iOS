import Foundation

/// Whole blocks over the preview rows. A big block is split into many rows (text pieces, code pieces, table pages),
/// and the selection always takes all rows of a block. A list item and a quote child are blocks of their own.
@MainActor
enum PreviewBlocks {
    /// The rows of the block that holds `row`. O(rows of that block).
    static func rows(ofBlockAt row: Int, in store: PreviewRowStore) -> ClosedRange<Int> {
        var first = row
        while first > 0, store[first].continuesBlock { first -= 1 }
        var last = row
        while last + 1 < store.count, store[last + 1].continuesBlock { last += 1 }
        return first...last
    }

    /// The text of the blocks in `rows` without Markdown syntax, blocks joined by a blank line.
    /// Blocks with no text (a divider, a notice) are left out.
    static func plainText(of rows: ClosedRange<Int>, in store: PreviewRowStore) -> String {
        var blocks: [String] = []
        var block = ""
        var table: TableText?
        func finishBlock() {
            if let finished = table?.text { block = finished }
            if !block.isEmpty { blocks.append(block) }
            block = ""
            table = nil
        }
        for index in rows {
            let row = store[index]
            if !row.continuesBlock { finishBlock() }
            switch row.content {
            case .block(let parsed):
                block = parsed.plainText
            case .textPiece(let text, _, _):
                block += text.text
            case .codePiece(_, let code, let isFirst, _, let continuesLine), .plainText(let code, let isFirst, _, let continuesLine):
                // A cut line goes on in the next piece after the marker, with no line end between.
                if isFirst {
                    block = code
                } else if continuesLine {
                    block += code.dropFirst(PreviewRows.codeContinuationMarker.count)
                } else {
                    block += "\n" + code
                }
            case .tablePage(let parsed, let pageRows, let isFirst, _):
                if isFirst || table == nil { table = TableText(header: parsed.header) }
                table?.add(parsed.rows[pageRows])
            case .notice:
                block = ""
            }
        }
        finishBlock()
        return blocks.joined(separator: "\n\n")
    }

    /// Table text: one line per row, cells joined by a tab.
    private struct TableText {
        var lines: [String]

        init(header: [InlineText]) {
            lines = [header.map(\.text).joined(separator: "\t")]
        }

        mutating func add(_ rows: ArraySlice<[InlineText]>) {
            lines += rows.map { $0.map(\.text).joined(separator: "\t") }
        }

        var text: String { lines.joined(separator: "\n") }
    }
}

extension PreviewRow {
    /// True for a piece or page after the first one of a split block.
    var continuesBlock: Bool {
        switch content {
        case .textPiece(_, _, let isFirst), .codePiece(_, _, let isFirst, _, _), .tablePage(_, _, let isFirst, _),
             .plainText(_, let isFirst, _, _):
            !isFirst
        case .block, .notice:
            false
        }
    }
}

extension ParsedBlock {
    /// The block's text without Markdown syntax. Children of lists and quotes go on their own lines.
    var plainText: String {
        switch kind {
        case .heading(_, let text), .paragraph(let text):
            text.text
        case .codeBlock(_, let code):
            code
        case .table(let table):
            ([table.header] + table.rows).map { $0.map(\.text).joined(separator: "\t") }.joined(separator: "\n")
        case .image(_, let altText):
            altText
        case .thematicBreak:
            ""
        case .list(let list):
            list.items.flatMap(\.blocks).map(\.plainText).filter { !$0.isEmpty }.joined(separator: "\n")
        case .blockQuote(let children):
            children.map(\.plainText).filter { !$0.isEmpty }.joined(separator: "\n")
        }
    }
}
