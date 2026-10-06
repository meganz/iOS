import Foundation

/// A parsed Markdown document. It is a plain value tree with no UI types.
/// The parser builds it off the main thread. The views only read it.
public struct MarkdownDocument: Equatable, Sendable {
    public var blocks: [MarkdownBlock]

    public init(blocks: [MarkdownBlock]) {
        self.blocks = blocks
    }
}

/// One block of the document. Container blocks (list items, quotes) hold child blocks.
public struct MarkdownBlock: Identifiable, Equatable, Sendable {
    /// Unique inside one document. Assigned in document order, depth first.
    public let id: Int
    /// 0-based line in the source text where this block starts.
    public let sourceLine: Int
    public var kind: Kind

    public init(id: Int, sourceLine: Int, kind: Kind) {
        self.id = id
        self.sourceLine = sourceLine
        self.kind = kind
    }

    public indirect enum Kind: Equatable, Sendable {
        /// Level 1...6.
        case heading(level: Int, text: AttributedString)
        case paragraph(AttributedString)
        case list(MarkdownList)
        /// `code` has no trailing newline. Its line ends are `\n`, also for CRLF or CR input.
        case codeBlock(language: String?, code: String)
        case blockQuote([MarkdownBlock])
        case table(MarkdownTable)
        case thematicBreak
        /// A paragraph that holds only one image.
        case image(url: URL?, altText: String)
    }
}

public struct MarkdownList: Equatable, Sendable {
    public var isOrdered: Bool
    /// First number of an ordered list. 1 for bullet lists.
    public var startIndex: Int
    public var items: [MarkdownListItem]

    public init(isOrdered: Bool, startIndex: Int, items: [MarkdownListItem]) {
        self.isOrdered = isOrdered
        self.startIndex = startIndex
        self.items = items
    }
}

public struct MarkdownListItem: Equatable, Sendable {
    /// Set for GFM task items: `- [ ] todo` or `- [x] done`.
    public var checkbox: Checkbox?
    public var blocks: [MarkdownBlock]

    public init(checkbox: Checkbox? = nil, blocks: [MarkdownBlock]) {
        self.checkbox = checkbox
        self.blocks = blocks
    }

    public enum Checkbox: Equatable, Sendable {
        case checked
        case unchecked
    }
}

public struct MarkdownTable: Equatable, Sendable {
    public var columns: [Column]
    /// One cell per column.
    public var header: [AttributedString]
    /// Each row has exactly `columns.count` cells. Missing cells are empty.
    public var rows: [[AttributedString]]

    public init(columns: [Column], header: [AttributedString], rows: [[AttributedString]]) {
        self.columns = columns
        self.header = header
        self.rows = rows
    }

    public struct Column: Equatable, Sendable {
        public var alignment: Alignment

        public init(alignment: Alignment) {
            self.alignment = alignment
        }
    }

    public enum Alignment: Equatable, Sendable {
        case none
        case left
        case center
        case right
    }
}
