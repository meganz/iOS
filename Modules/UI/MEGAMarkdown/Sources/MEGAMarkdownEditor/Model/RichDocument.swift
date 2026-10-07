import Foundation

/// The rich editor's document: a flat list of blocks.
/// Markdown exists only at the file boundary. `RichMarkdownConverter` builds the document on load and writes Markdown on save.
struct RichDocument: Equatable, Sendable {
    var blocks: [RichBlock]
    /// File details that are not content. Export writes them back.
    var format: RichFileFormat

    init(blocks: [RichBlock], format: RichFileFormat = RichFileFormat()) {
        self.blocks = blocks
        self.format = format
    }
}

/// Bytes of a Markdown file that the blocks do not hold.
struct RichFileFormat: Equatable, Sendable {
    /// The blocks always use "\n". Export writes this line ending.
    var lineEnding: RichLineEnding = .lf
    /// The file starts with U+FEFF. cmark skips it, so the blocks never hold it.
    var hasByteOrderMark = false
    /// The last line of the file ends with a line ending.
    var endsWithLineEnding = true
}

/// Line ending of a Markdown file. Taken from the first line end in the file.
enum RichLineEnding: Equatable, Sendable {
    /// "\n" (macOS, Linux, iOS).
    case lf
    /// "\r\n" (Windows).
    case crlf
    /// "\r" (classic Mac OS).
    case cr

    var text: String {
        switch self {
        case .lf: "\n"
        case .crlf: "\r\n"
        case .cr: "\r"
        }
    }

    /// The ending of the first line in `markdown`. A text with no line end is `.lf`.
    static func detect(in markdown: String) -> RichLineEnding {
        var bytes = markdown.utf8.makeIterator()
        while let byte = bytes.next() {
            if byte == 10 { return .lf }
            if byte == 13 { return bytes.next() == 10 ? .crlf : .cr }
        }
        return .lf
    }
}

/// One editable row. Lists and quotes are flat rows with an indent or a depth, like the Android editor.
enum RichBlock: Hashable, Sendable {
    case paragraph(RichText)
    /// Level 1...6.
    case heading(level: Int, text: RichText)
    case listItem(RichListItem, text: RichText)
    /// Depth 1 means one `>`.
    case quote(depth: Int, text: RichText)
    /// `code` has "\n" line ends and no line end after its last line.
    case codeBlock(language: String?, code: String)
    case thematicBreak
    /// Markdown the editor does not model (tables, images, HTML, lists with block content).
    /// Export writes it back byte for byte. It is read-only.
    case rawSource(String)
}

extension RichBlock {
    /// Code and raw source compare by bytes. `String ==` treats "é" and "e" + U+0301 as equal,
    /// and an edit that only changes the form would look like no change and never save.
    static func == (lhs: RichBlock, rhs: RichBlock) -> Bool {
        switch (lhs, rhs) {
        case let (.paragraph(left), .paragraph(right)): left == right
        case let (.heading(leftLevel, left), .heading(rightLevel, right)): leftLevel == rightLevel && left == right
        case let (.listItem(leftItem, left), .listItem(rightItem, right)): leftItem == rightItem && left == right
        case let (.quote(leftDepth, left), .quote(rightDepth, right)): leftDepth == rightDepth && left == right
        case let (.codeBlock(leftLanguage, leftCode), .codeBlock(rightLanguage, rightCode)):
            leftCode.hasSameBytes(as: rightCode) && Self.sameBytes(leftLanguage, rightLanguage)
        case (.thematicBreak, .thematicBreak): true
        case let (.rawSource(left), .rawSource(right)): left.hasSameBytes(as: right)
        default: false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .paragraph(let text): hasher.combine(0); hasher.combine(text)
        case .heading(let level, let text): hasher.combine(1); hasher.combine(level); hasher.combine(text)
        case .listItem(let item, let text): hasher.combine(2); hasher.combine(item); hasher.combine(text)
        case .quote(let depth, let text): hasher.combine(3); hasher.combine(depth); hasher.combine(text)
        // Equal bytes give equal counts, so the count is a valid and cheap hash for big code.
        case .codeBlock(_, let code): hasher.combine(4); hasher.combine(code.utf8.count)
        case .thematicBreak: hasher.combine(5)
        case .rawSource(let source): hasher.combine(6); hasher.combine(source.utf8.count)
        }
    }

    private static func sameBytes(_ left: String?, _ right: String?) -> Bool {
        switch (left, right) {
        case (nil, nil): true
        case let (left?, right?): left.hasSameBytes(as: right)
        default: false
        }
    }
}

struct RichListItem: Equatable, Hashable, Sendable {
    var isOrdered: Bool
    /// 0 is top level.
    var indent: Int
    /// nil for a normal item. true or false for a task item.
    var isChecked: Bool?
    /// Set only on the first item of an ordered run that does not start at 1. Later items count up from it.
    var startNumber: Int?

    init(isOrdered: Bool, indent: Int = 0, isChecked: Bool? = nil, startNumber: Int? = nil) {
        self.isOrdered = isOrdered
        self.indent = indent
        self.isChecked = isChecked
        self.startNumber = startNumber
    }
}

// MARK: - Block access

extension RichBlock {
    /// The inline text of a paragraph, heading, list item or quote. nil for the other kinds.
    var richText: RichText? {
        switch self {
        case .paragraph(let text), .heading(_, let text), .listItem(_, let text), .quote(_, let text):
            text
        case .codeBlock, .thematicBreak, .rawSource:
            nil
        }
    }

    /// Same kind with new text. Blocks without inline text stay as they are.
    func withText(_ text: RichText) -> RichBlock {
        switch self {
        case .paragraph: .paragraph(text)
        case .heading(let level, _): .heading(level: level, text: text)
        case .listItem(let item, _): .listItem(item, text: text)
        case .quote(let depth, _): .quote(depth: depth, text: text)
        case .codeBlock, .thematicBreak, .rawSource: self
        }
    }

    var codeText: String? {
        if case .codeBlock(_, let code) = self { code } else { nil }
    }

    /// The text a block's text view shows. nil for a divider and a raw block.
    var plainText: String? {
        richText?.text ?? codeText
    }

    var isRawSource: Bool {
        if case .rawSource = self { true } else { false }
    }

    /// Caret positions in the block run from 0 to `length`.
    /// A divider and a raw block have no text: 0 is before the block and 1 is after it.
    var length: Int {
        plainText?.utf16.count ?? 1
    }

    var listItem: RichListItem? {
        if case .listItem(let item, _) = self { item } else { nil }
    }
}
