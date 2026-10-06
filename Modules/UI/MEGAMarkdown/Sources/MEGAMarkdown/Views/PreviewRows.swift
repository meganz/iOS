import Foundation
import MEGAFoundation

/// One row of the preview. A normal block is one row. A big block (long list, table, code or text)
/// is split into many rows, so a list view builds only the part on screen.
package struct PreviewRow: Equatable, Sendable {
    package enum Content: Equatable, Sendable {
        /// A whole block, drawn by `MarkdownBlockView`.
        case block(ParsedBlock)
        /// Part of a long paragraph (`headingLevel` nil) or heading.
        case textPiece(InlineText, headingLevel: Int?, isFirst: Bool)
        case codePiece(language: String?, code: String, isFirst: Bool, isLast: Bool)
        /// Some rows of a big table. `rows` are indexes into `table.rows`.
        case tablePage(ParsedTable, rows: Range<Int>, isFirst: Bool, isLast: Bool)
        /// Raw source lines, shown when a part of the file is too big to format.
        case plainText(String, isFirst: Bool, isLast: Bool)
        /// Tells the reader that the content below is not the full formatted file.
        case notice(Notice)
    }

    package enum Notice: Equatable, Sendable {
        /// The rows below are raw source text.
        case shownAsPlainText
        /// The rest of the file is not shown (memory limit).
        case restTooLarge
    }

    package var sourceLine: Int
    package var chrome: MarkdownRowChrome
    package var content: Content

    package init(sourceLine: Int, chrome: MarkdownRowChrome = MarkdownRowChrome(), content: Content) {
        self.sourceLine = sourceLine
        self.chrome = chrome
        self.content = content
    }
}

package enum PreviewRows {
    /// A block heavier than this is split. Weight = blocks + table cells / 5 + code lines / 10 + text bytes / 200.
    /// So one row holds at most about 20 KB of text, 1,000 code lines or 500 table cells.
    static let maxRowWeight = 100
    /// UTF-8 bytes per text piece. The cut moves back to a space or newline when one is close.
    static let textPieceBytes = 4_000
    static let codePieceLines = 100
    /// A code line longer than this is cut. The next piece starts with `codeContinuationMarker`.
    static let codePieceBytes = 8_000
    static let codeContinuationMarker = "↪ "
    static let tableCellsPerPage = 500
    static let tableRowsPerPage = 50

    /// Rows of a small Markdown string, parsed whole.
    /// Every block is split (row weight 0), so each row is one short, flat piece.
    /// A caller can show each row with `PreviewRowView`, outside any list view.
    /// Returns no rows when the Markdown shows nothing. A caller that needs a visible item shows the source itself.
    package static func rows(forMarkdown markdown: String, softBreak: MarkdownSoftBreak) -> [PreviewRow] {
        rows(for: CmarkParser.blocks(markdown, softBreak: softBreak) ?? [], maxWeight: 0)
    }

    /// A lower `maxWeight` splits smaller blocks. 0 splits every block, so each row is one short, flat piece.
    static func rows(for blocks: [ParsedBlock], maxWeight: Int = maxRowWeight) -> [PreviewRow] {
        var builder = Builder(maxWeight: maxWeight)
        for block in blocks {
            builder.append(block, decorations: [], gap: .block)
        }
        return builder.rows
    }

    // MARK: - Weight

    static func weight(of block: ParsedBlock) -> Int {
        switch block.kind {
        case .heading(_, let text), .paragraph(let text):
            return 1 + text.text.utf8.count / 200
        case .codeBlock(_, let code):
            let lines = code.utf8.reduce(0) { $0 + ($1 == 10 ? 1 : 0) }
            return 1 + lines / 10 + code.utf8.count / 200
        case .table(let table):
            let cells = (table.rows.count + 1) * table.columns.count
            let bytes = table.rows.reduce(0) { total, row in total + row.reduce(0) { $0 + $1.text.utf8.count } }
            return 1 + cells / 5 + bytes / 200
        case .blockQuote(let children):
            return children.reduce(1) { $0 + weight(of: $1) }
        case .list(let list):
            return list.items.reduce(1) { total, item in item.blocks.reduce(total) { $0 + weight(of: $1) } }
        case .thematicBreak, .image:
            return 1
        }
    }

    /// Container levels inside the block (0 for a leaf).
    static func nesting(of block: ParsedBlock) -> Int {
        switch block.kind {
        case .blockQuote(let children):
            return 1 + (children.map(nesting).max() ?? 0)
        case .list(let list):
            return 1 + (list.items.flatMap(\.blocks).map(nesting).max() ?? 0)
        default:
            return 0
        }
    }

    // MARK: - Builder

    struct Builder {
        let maxWeight: Int
        var rows: [PreviewRow] = []

        mutating func append(_ block: ParsedBlock, decorations: [MarkdownRowDecoration], gap: MarkdownRowGap) {
            if case .table(let table) = block.kind, table.columns.count > TableLimits.maxColumns {
                MEGALog.log(
                    level: .info,
                    message: "[PreviewRows] Table columns over the limit are hidden. columns=\(table.columns.count) shown=\(TableLimits.maxColumns)"
                )
            }
            let fitsOneRow = weight(of: block) <= maxWeight && decorations.count + nesting(of: block) <= MarkdownRowChrome.maxVisibleNesting
            if fitsOneRow {
                add(PreviewRow(sourceLine: block.sourceLine, chrome: MarkdownRowChrome(decorations: decorations), content: .block(block)), gap: gap)
                return
            }
            switch block.kind {
            case .paragraph(let text):
                appendTextPieces(text, headingLevel: nil, line: block.sourceLine, decorations: decorations, gap: gap)
            case .heading(let level, let text):
                appendTextPieces(text, headingLevel: level, line: block.sourceLine, decorations: decorations, gap: gap)
            case .codeBlock(let language, let code):
                appendCodePieces(code, language: language, line: block.sourceLine, decorations: decorations, gap: gap)
            case .table(let table):
                appendTablePages(table, line: block.sourceLine, decorations: decorations, gap: gap)
            case .blockQuote(let children):
                let firstRow = rows.count
                for (index, child) in children.enumerated() {
                    let start = rows.count
                    append(child, decorations: decorations + [.quote], gap: index == 0 ? gap : .nested)
                    if index > 0 { setGapColumns(above: start, enclosing: decorations.count + 1) }
                }
                markQuoteEnds(level: decorations.count, rows: firstRow..<rows.count)
            case .list(let list):
                appendList(list, line: block.sourceLine, decorations: decorations, gap: gap)
            case .thematicBreak, .image:
                add(PreviewRow(sourceLine: block.sourceLine, chrome: MarkdownRowChrome(decorations: decorations), content: .block(block)), gap: gap)
            }
        }

        /// Raw lines, about 100 per row, after a notice that says so.
        mutating func appendPlainText(_ text: String, firstLine: Int) {
            add(PreviewRow(sourceLine: firstLine, content: .notice(.shownAsPlainText)), gap: .block)
            // Lines can also end with CR only (like in cmark), so make every line end "\n" first.
            let lines = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
            let pieces = Self.codePieces(lines)
            for (index, piece) in pieces.enumerated() {
                let content = PreviewRow.Content.plainText(piece.text, isFirst: index == 0, isLast: index == pieces.count - 1)
                add(PreviewRow(sourceLine: firstLine + piece.lineOffset, content: content), gap: index == 0 ? .nested : .none)
            }
        }

        mutating func appendNotice(_ notice: PreviewRow.Notice, line: Int) {
            add(PreviewRow(sourceLine: line, content: .notice(notice)), gap: .block)
        }

        /// The gap above row `start` sits inside the first `enclosing` decoration columns of the row before.
        private mutating func setGapColumns(above start: Int, enclosing: Int) {
            guard start > 0, start < rows.count else { return }
            rows[start - 1].chrome.gapOutsideColumns = UInt8(clamping: rows[start - 1].chrome.decorations.count - enclosing)
        }

        /// Marks the first and last row of a quote at decoration `level`, where its bar has round corners.
        private mutating func markQuoteEnds(level: Int, rows range: Range<Int>) {
            guard let first = range.first, let last = range.last, level < MarkdownRowChrome.maxVisibleNesting else { return }
            let bit = UInt8(1) << level
            rows[first].chrome.quoteTops |= bit
            rows[last].chrome.quoteBottoms |= bit
        }

        /// Sets the gap below the row before, then adds the row.
        private mutating func add(_ row: PreviewRow, gap: MarkdownRowGap) {
            if !rows.isEmpty { rows[rows.count - 1].chrome.gapBelow = gap }
            rows.append(row)
        }

        private mutating func appendList(_ list: ParsedList, line: Int, decorations: [MarkdownRowDecoration], gap: MarkdownRowGap) {
            for (itemIndex, item) in list.items.enumerated() {
                let marker: MarkdownListMarker
                if let checkbox = item.checkbox {
                    marker = .checkbox(isChecked: checkbox == .checked)
                } else if list.isOrdered {
                    marker = .number(list.startIndex + itemIndex)
                } else {
                    marker = .bullet
                }
                let firstRow = rows.count
                // An empty item still shows its marker, like `ListBlockView`. It gets an empty paragraph to hold it.
                // The parser keeps no line for it, so it takes the line of the row before.
                let blocks = item.blocks.isEmpty
                    ? [ParsedBlock(sourceLine: rows.last.map { max($0.sourceLine, line) } ?? line, kind: .paragraph(InlineText()))]
                    : item.blocks
                for (blockIndex, child) in blocks.enumerated() {
                    let childGap: MarkdownRowGap
                    if blockIndex > 0 {
                        childGap = .nested
                    } else if itemIndex > 0 {
                        let taskItems = (list.items[itemIndex - 1].checkbox == nil ? 0 : 1) + (item.checkbox == nil ? 0 : 1)
                        childGap = .betweenItems(taskItems: taskItems)
                    } else {
                        childGap = gap
                    }
                    let start = rows.count
                    append(child, decorations: decorations + [.listItem(marker, showsMarker: true)], gap: childGap)
                    // Between items the gap is outside this item's marker. Between blocks of one item it is inside.
                    if blockIndex > 0 {
                        setGapColumns(above: start, enclosing: decorations.count + 1)
                    } else if itemIndex > 0 {
                        setGapColumns(above: start, enclosing: decorations.count)
                    }
                }
                // Only the item's first row shows the marker.
                let level = decorations.count
                for index in (firstRow + 1)..<max(firstRow + 1, rows.count) {
                    rows[index].chrome.decorations[level] = .listItem(marker, showsMarker: false)
                }
            }
        }

        private mutating func appendTextPieces(
            _ text: InlineText,
            headingLevel: Int?,
            line: Int,
            decorations: [MarkdownRowDecoration],
            gap: MarkdownRowGap
        ) {
            var pieceLine = line
            for (index, range) in Self.textPieceRanges(text.text).enumerated() {
                let piece = text.slice(range)
                let content = PreviewRow.Content.textPiece(piece, headingLevel: headingLevel, isFirst: index == 0)
                add(PreviewRow(sourceLine: pieceLine, chrome: MarkdownRowChrome(decorations: decorations), content: content), gap: index == 0 ? gap : .none)
                pieceLine += Self.breakCount(in: piece)
            }
        }

        private mutating func appendCodePieces(
            _ code: String,
            language: String?,
            line: Int,
            decorations: [MarkdownRowDecoration],
            gap: MarkdownRowGap
        ) {
            let pieces = Self.codePieces(code)
            for (index, piece) in pieces.enumerated() {
                let content = PreviewRow.Content.codePiece(
                    language: index == 0 ? language : nil,
                    code: piece.text,
                    isFirst: index == 0,
                    isLast: index == pieces.count - 1
                )
                // +1: fenced code starts on the line after the fence. Indented code is then one line off (only for big blocks).
                let pieceLine = index == 0 ? line : line + 1 + piece.lineOffset
                add(PreviewRow(sourceLine: pieceLine, chrome: MarkdownRowChrome(decorations: decorations), content: content), gap: index == 0 ? gap : .none)
            }
        }

        private mutating func appendTablePages(_ table: ParsedTable, line: Int, decorations: [MarkdownRowDecoration], gap: MarkdownRowGap) {
            let shownColumns = max(1, min(table.columns.count, TableLimits.maxColumns))
            let pageSize = max(1, min(tableRowsPerPage, tableCellsPerPage / shownColumns))
            var start = 0
            repeat {
                let end = min(start + pageSize, table.rows.count)
                let content = PreviewRow.Content.tablePage(table, rows: start..<end, isFirst: start == 0, isLast: end == table.rows.count)
                // The parser drops empty rows, so a row index is not a line offset. `rowLines` keeps each row's own line.
                let rowLine = start == 0 ? line : table.rowLines[start]
                add(PreviewRow(sourceLine: rowLine, chrome: MarkdownRowChrome(decorations: decorations), content: content), gap: start == 0 ? gap : .none)
                start = end
            } while start < table.rows.count
        }

        // MARK: Helpers

        /// Soft and hard breaks are one byte each, and each ends a source line.
        private static func breakCount(in text: InlineText) -> Int {
            var count = 0
            var start = 0
            for run in text.runs {
                if run.style.contains(.softBreak) || run.style.contains(.lineBreak) { count += run.end - start }
                start = run.end
            }
            return count
        }

        /// UTF-8 ranges of about `textPieceBytes`, cut on character boundaries.
        /// The cut moves back to just after a newline when one is in the last 800 bytes, else just after a space.
        /// A piece cut after a newline keeps it. `PreviewRowView` does not draw it, so that seam shows no empty line.
        /// A cut after a space leaves a short last line in its piece.
        static func textPieceRanges(_ text: String) -> [Range<Int>] {
            let total = text.utf8.count
            guard total > textPieceBytes else { return [0..<total] }
            var ranges: [Range<Int>] = []
            var start = 0
            var offset = 0
            var lastSpaceEnd = 0
            var lastNewlineEnd = 0
            for character in text {
                let size = character.utf8.count
                if offset > start, offset + size - start > textPieceBytes {
                    let cut = if lastNewlineEnd > start && offset - lastNewlineEnd < 800 {
                        lastNewlineEnd
                    } else if lastSpaceEnd > start && offset - lastSpaceEnd < 800 {
                        lastSpaceEnd
                    } else {
                        offset
                    }
                    ranges.append(start..<cut)
                    start = cut
                }
                offset += size
                if character == " " || character.isNewline { lastSpaceEnd = offset }
                if character.isNewline { lastNewlineEnd = offset }
            }
            ranges.append(start..<offset)
            return ranges
        }

        struct CodePiece: Equatable {
            var text: String
            /// Lines before this piece inside the code.
            var lineOffset: Int
        }

        /// Pieces of at most `codePieceLines` lines and about `codePieceBytes` bytes.
        static func codePieces(_ code: String) -> [CodePiece] {
            var pieces: [CodePiece] = []
            var lines: [String] = []
            var bytes = 0
            var startLine = 0
            for (lineNumber, line) in code.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                for (partIndex, part) in longLineParts(line).enumerated() {
                    // A cut line goes on in the next part. The marker makes the cut visible.
                    let text = partIndex == 0 ? String(part) : codeContinuationMarker + part
                    if !lines.isEmpty, lines.count >= codePieceLines || bytes + text.utf8.count > codePieceBytes {
                        pieces.append(CodePiece(text: lines.joined(separator: "\n"), lineOffset: startLine))
                        lines = []
                        bytes = 0
                        startLine = lineNumber
                    }
                    lines.append(text)
                    bytes += text.utf8.count + 1
                }
            }
            pieces.append(CodePiece(text: lines.joined(separator: "\n"), lineOffset: startLine))
            return pieces
        }

        /// Cuts a line into parts of at most `codePieceBytes` bytes, on character boundaries.
        private static func longLineParts(_ line: Substring) -> [Substring] {
            guard line.utf8.count > codePieceBytes else { return [line] }
            var parts: [Substring] = []
            var partStart = line.startIndex
            var bytes = 0
            var index = line.startIndex
            while index < line.endIndex {
                let size = line[index].utf8.count
                if bytes + size > codePieceBytes, index > partStart {
                    parts.append(line[partStart..<index])
                    partStart = index
                    bytes = 0
                }
                bytes += size
                index = line.index(after: index)
            }
            parts.append(line[partStart...])
            return parts
        }
    }
}

/// Caps that keep one table view small. Both whole tables and table pages use them.
enum TableLimits {
    /// More columns are not drawn. A last "…" column shows that some are hidden.
    static let maxColumns = 64
    /// Longer cell text is cut and ends with "…".
    static let maxCellCharacters = 2_000
}

// MARK: - Line lookup

/// Index of the row that contains `line`: the last row that starts at or before it.
/// Rows are in source order, so binary search works. Nil when there are no rows.
func rowIndex(containing line: Int, in rows: [PreviewRow]) -> Int? {
    guard !rows.isEmpty else { return nil }
    var low = 0
    var high = rows.count
    while low < high {
        let middle = (low + high) / 2
        if rows[middle].sourceLine <= line { low = middle + 1 } else { high = middle }
    }
    return max(low - 1, 0)
}
