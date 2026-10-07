import Foundation
import MEGAFoundation

/// Rich blocks -> Markdown body: "\n" line ends and no line end after the last line.
/// `MarkdownSourceText.file(body:format:)` adds the file's line ending and byte order mark.
///
/// The output parses back to the same blocks, except for texts whose styles do not parse back (see `lossyTextCount`).
/// Exporting twice gives the same bytes.
/// Raw blocks are written byte for byte.
struct MarkdownExporter {
    let blocks: [RichBlock]
    /// Inline pieces of the last export. A text that did not change is not written or checked again.
    let previous: InlineExportCache
    /// Pieces of this export. Only texts still in the document, so the cache never grows.
    private(set) var current = InlineExportCache()
    /// Texts of this export whose styles may change on reopen (see `InlineWriter.write`).
    private(set) var lossyTextCount = 0

    init(blocks: [RichBlock], previous: InlineExportCache = InlineExportCache()) {
        self.blocks = blocks
        self.previous = previous
    }

    mutating func markdown() -> String {
        var output = ""
        var previousBlock: RichBlock?
        var list = MarkdownListState()
        // An empty paragraph right after a list item or quote: the next list or quote must start as a new one.
        var pendingListBreak = false
        var pendingQuoteBreak = false
        // The written text of the last list item. An empty one cannot hold a blank line before its children.
        var previousItemIsEmpty = true
        let orderedNumbers = RichDocument.orderedNumbers(of: blocks)

        for (index, block) in blocks.enumerated() {
            guard !Self.isSkipped(block) else {
                // Any block between list items ends the run of shown numbers, so the next item starts a new list.
                if case .listItem = previousBlock { pendingListBreak = true }
                if case .paragraph = block, case .quote = previousBlock { pendingQuoteBreak = true }
                continue
            }
            var piece: String
            var separator = "\n\n"

            switch block {
            case .listItem(let item, let text):
                let continuesList = previousBlock?.listItem != nil
                if !continuesList { list = MarkdownListState() }
                let content = inline(text, context: .listItem(continuationIndent: list.contentColumn(of: item, number: orderedNumbers[index] ?? 1)))
                let line = list.next(
                    item: item, number: orderedNumbers[index] ?? 1, forceNewList: pendingListBreak,
                    parentHasText: continuesList && !previousItemIsEmpty, isEmpty: content.isEmpty
                )
                previousItemIsEmpty = content.isEmpty
                piece = String(repeating: " ", count: line.column) + line.marker + Self.taskMarker(item) + content
                if content.isEmpty && item.isChecked == nil {
                    // An empty item is the marker alone. A task keeps its space: GFM needs one after `[ ]`.
                    piece = String(piece.dropLast())
                }
                if continuesList {
                    separator = line.startsNewList ? "\n\n" : "\n"
                }
            case .quote(let depth, let text):
                let prefix = Self.quotePrefix(depth)
                piece = prefix + inline(text, context: .quote(prefix: prefix))
                if case .quote(let previousDepth, _)? = previousBlock, !pendingQuoteBreak {
                    // A `>` line keeps both rows in one quote and stops lazy continuation.
                    separator = "\n" + Self.quotePrefix(min(depth, previousDepth)).trimmingCharacters(in: .whitespaces) + "\n"
                }
            case .paragraph(let text):
                piece = inline(text, context: .paragraph)
            case .heading(let level, let text):
                piece = Self.heading(level: min(max(level, 1), 6), text: text) { inline(text, context: $0) }
            case .codeBlock(let language, let code):
                piece = Self.codeBlock(language: language, code: code)
            case .thematicBreak:
                piece = "---"
            case .rawSource(let source):
                piece = source
            }

            if previousBlock != nil { output += separator }
            output += piece
            previousBlock = block
            pendingListBreak = false
            pendingQuoteBreak = false
        }
        if lossyTextCount > 0 {
            MEGALog.log(level: .warning, message: "[MarkdownExporter] Styles do not parse back, so they may change on reopen. texts=\(lossyTextCount)")
        }
        return output
    }

    /// The re-parse check in `InlineWriter.write` is most of the export time, so each piece is written once.
    private mutating func inline(_ text: RichText, context: InlineWriter.Context) -> String {
        let key = InlineExportCache.Key(text: text, context: context)
        if let piece = current.pieces[key] ?? previous.pieces[key] {
            current.pieces[key] = piece
            return piece
        }
        let (piece, roundTrips) = InlineWriter.write(text, context: context)
        if !roundTrips { lossyTextCount += 1 }
        current.pieces[key] = piece
        return piece
    }

    /// Empty paragraphs and empty quote rows would vanish on re-parse, so they are not written.
    private static func isSkipped(_ block: RichBlock) -> Bool {
        switch block {
        case .paragraph(let text), .quote(_, let text):
            InlineWriter.isBlank(text)
        case .rawSource(let source):
            source.utf8.allSatisfy { $0 == 32 || $0 == 9 || $0 == 10 }
        default:
            false
        }
    }

    private static func quotePrefix(_ depth: Int) -> String {
        String(repeating: "> ", count: max(depth, 1))
    }

    private static func taskMarker(_ item: RichListItem) -> String {
        switch item.isChecked {
        case true?: "[x] "
        case false?: "[ ] "
        case nil: ""
        }
    }

    /// A level 1 or 2 heading with line breaks is written as a setext heading, which keeps them.
    /// Other headings are one ATX line. Their breaks become spaces.
    private static func heading(level: Int, text: RichText, write: (InlineWriter.Context) -> String) -> String {
        let hasBreak = text.text.utf16.contains { $0 == 10 || $0 == 0x2028 }
        if hasBreak && level <= 2 {
            // A break at the text edge is dropped, so the written text may have none. Then it is one ATX line.
            let content = write(.setextHeading)
            if content.contains("\n") {
                return content + "\n" + (level == 1 ? "===" : "---")
            }
        }
        let content = write(.atxHeading)
        return String(repeating: "#", count: level) + (content.isEmpty ? "" : " " + content)
    }

    /// A fence longer than any backtick run in the code. An info string with a backtick needs a tilde fence.
    private static func codeBlock(language: String?, code: String) -> String {
        let info = language ?? ""
        let fenceCharacter: Unicode.Scalar = info.unicodeScalars.contains("`") ? "~" : "`"
        var longest = 0
        var run = 0
        for scalar in code.unicodeScalars {
            run = scalar == fenceCharacter ? run + 1 : 0
            longest = max(longest, run)
        }
        let fence = String(repeating: String(fenceCharacter), count: max(3, longest + 1))
        return code.isEmpty ? "\(fence)\(info)\n\(fence)" : "\(fence)\(info)\n\(code)\n\(fence)"
    }
}

/// Written inline Markdown per block text, kept between exports of one editor.
struct InlineExportCache: Sendable {
    /// Compares and hashes text by bytes, like `RichText`.
    struct Key: Hashable, Sendable {
        let text: RichText
        let context: InlineWriter.Context
    }

    fileprivate(set) var pieces: [Key: String] = [:]
}

// MARK: - Lists

/// Marker columns and list identity while writing one run of list items.
private struct MarkdownListState {
    struct Line {
        let column: Int
        let contentColumn: Int
        let marker: String
        let startsNewList: Bool
    }

    private struct Level {
        let column: Int
        let isOrdered: Bool
        let delimiter: Character
        let bullet: Character
        let contentColumn: Int
    }

    /// CommonMark reads at most 9 digits as a list number.
    private static let maxNumber = 999_999_999

    private var levels: [Level] = []

    /// Where the item's text starts, before `next` adds the item.
    func contentColumn(of item: RichListItem, number: Int) -> Int {
        let depth = min(item.indent, levels.count)
        let column = depth == 0 ? 0 : levels[depth - 1].contentColumn
        return column + marker(item, number: number, delimiter: ".", bullet: "-").count
    }

    /// `parentHasText`: the line before is the text of the item above. A new list under it cannot start empty
    /// (an empty item cannot interrupt a paragraph, and `-` alone would underline the text as a heading)
    /// and an ordered one must start at 1. Such a list needs a blank line before it.
    /// An empty parent is the other way round: a blank line would end it, so its children follow at once.
    mutating func next(item: RichListItem, number: Int, forceNewList: Bool, parentHasText: Bool, isEmpty: Bool) -> Line {
        let depth = min(item.indent, levels.count)
        var startsNewList = false
        let column = depth == 0 ? 0 : levels[depth - 1].contentColumn
        var delimiter: Character = "."
        var bullet: Character = "-"

        if depth < levels.count {
            let level = levels[depth]
            let sameKind = level.isOrdered == item.isOrdered
            let newRun = (item.isOrdered && item.startNumber != nil) || forceNewList
            if sameKind && !newRun {
                delimiter = level.delimiter
                bullet = level.bullet
            } else {
                startsNewList = true
                // Two lists of the same kind next to each other need a different marker, or they merge.
                if sameKind {
                    delimiter = level.delimiter == "." ? ")" : "."
                    bullet = level.bullet == "-" ? "*" : "-"
                }
            }
            levels.removeSubrange(depth...)
        } else if depth > 0 && parentHasText && (isEmpty || (item.isOrdered && number != 1)) {
            startsNewList = true
        }

        let marker = marker(item, number: number, delimiter: delimiter, bullet: bullet)
        let contentColumn = column + marker.count
        levels.append(Level(column: column, isOrdered: item.isOrdered, delimiter: delimiter, bullet: bullet, contentColumn: contentColumn))
        return Line(column: column, contentColumn: contentColumn, marker: marker, startsNewList: startsNewList)
    }

    private func marker(_ item: RichListItem, number: Int, delimiter: Character, bullet: Character) -> String {
        item.isOrdered ? "\(min(max(number, 0), Self.maxNumber))\(delimiter) " : "\(bullet) "
    }
}
