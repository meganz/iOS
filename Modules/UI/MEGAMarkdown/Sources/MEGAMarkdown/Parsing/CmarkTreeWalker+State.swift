// MARK: - Walk state

extension CmarkTreeWalker {
    /// One inline piece of a leaf block, before style tags are applied.
    struct Piece {
        var text: String
        var style: InlineStyle
        var link: Int
    }

    /// Style state inside a leaf. A new one is pushed for each emphasis, link or image.
    struct InlineContext {
        var style: InlineStyle = []
        var link = -1
        /// Inside an image, inner styles are dropped (Foundation shows plain alt text).
        var inImage = false
        /// Pieces before this link or image started. One with no text gets a placeholder on exit. -1: never.
        var piecesBeforeImage = 0
    }

    /// A block that is still open while the walk is inside it.
    struct Frame {
        enum Kind {
            case document
            case quote
            case list(isOrdered: Bool, start: Int)
            case item(checkbox: MarkdownListItem.Checkbox?)
            case table(columnCount: Int, columns: [MarkdownTable.Column])
            case tableRow(isHeader: Bool)
        }

        var kind: Kind
        var line: Int?
        var blocks: [ParsedBlock] = []
        var items: [ParsedListItem] = []
        /// Index of the first item that has content. Empty items are dropped, like Foundation does. Task items stay.
        var firstKeptItem: Int?
        var itemCount = 0
        var header: [InlineText] = []
        var rows: [[InlineText]] = []
        var rowLines: [Int] = []
        var cells: [InlineText] = []
    }

    /// The bytes cmark parsed: the definition prefix, then the body. Task markers are read here,
    /// because cmark's node text has escapes and entities already decoded.
    struct SourceText {
        private let prefix: UnsafeBufferPointer<UInt8>
        private let body: UnsafeBufferPointer<UInt8>
        /// Start offset of `cursorLine` (1-based, like cmark). Lines are asked for in document order, so the cursor moves forward.
        private var cursorLine = 1
        private var cursorOffset = 0

        init(prefix: UnsafeBufferPointer<UInt8>, body: UnsafeBufferPointer<UInt8>) {
            self.prefix = prefix
            self.body = body
        }

        private var count: Int { prefix.count + body.count }

        private subscript(offset: Int) -> UInt8 {
            offset < prefix.count ? prefix[offset] : body[offset - prefix.count]
        }

        /// Byte offset of a cmark position. cmark columns are 1-based byte columns.
        mutating func offset(line: Int, column: Int) -> Int? {
            guard line > 0, column > 0 else { return nil }
            if line < cursorLine {
                cursorLine = 1
                cursorOffset = 0
            }
            while cursorLine < line {
                guard let next = nextLineStart(after: cursorOffset) else { return nil }
                cursorOffset = next
                cursorLine += 1
            }
            let offset = cursorOffset + column - 1
            return offset < count ? offset : nil
        }

        /// The first byte after a list marker (`-`, `+`, `*`, or digits with `.` or `)`) and the spaces after it.
        func offsetAfterListMarker(at offset: Int) -> Int {
            var index = offset
            while index < count, Self.isDigit(self[index]) { index += 1 }
            // The bullet, or the `.` or `)` after the digits.
            index += 1
            while index < count, Self.isSpaceOrTab(self[index]) { index += 1 }
            return index
        }

        /// A GFM task marker at `offset`: `[ ]`, `[x]` or `[X]`, then a space or tab on the same line.
        func taskMarker(at offset: Int) -> MarkdownListItem.Checkbox? {
            guard offset + 3 < count,
                  self[offset] == UInt8(ascii: "["), self[offset + 2] == UInt8(ascii: "]"),
                  Self.isSpaceOrTab(self[offset + 3]) else { return nil }
            switch self[offset + 1] {
            case UInt8(ascii: " "): return .unchecked
            case UInt8(ascii: "x"), UInt8(ascii: "X"): return .checked
            default: return nil
            }
        }

        /// The spaces and tabs after the task marker at `offset`, and whether the line ends after them.
        func separatorAfterTaskMarker(at offset: Int) -> (count: Int, endsLine: Bool) {
            var index = offset + 3
            while index < count, Self.isSpaceOrTab(self[index]) { index += 1 }
            let endsLine = index == count || self[index] == 10 || self[index] == 13
            return (index - offset - 3, endsLine)
        }

        /// Line ends are `\n`, `\r\n` or `\r`, like cmark.
        private func nextLineStart(after start: Int) -> Int? {
            var index = start
            while index < count {
                let byte = self[index]
                if byte == 10 { return index + 1 }
                if byte == 13 { return index + 1 < count && self[index + 1] == 10 ? index + 2 : index + 1 }
                index += 1
            }
            return nil
        }

        private static func isDigit(_ byte: UInt8) -> Bool { byte >= 48 && byte <= 57 }

        private static func isSpaceOrTab(_ byte: UInt8) -> Bool { byte == 32 || byte == 9 }
    }

    enum ExtensionKind {
        case table
        case tableRow
        case tableCell
        case strikethrough
        case other
    }
}
