import cmark_gfm
import cmark_gfm_extensions

/// Walks a cmark tree into `ParsedBlock`s. "Foundation" in the comments means `AttributedString(markdown:)`,
/// the parser tried before this one. `ParserGoldenTests` pins the output that matched it.
struct CmarkTreeWalker {
    private let softBreak: MarkdownSoftBreak

    private var frames = [Frame(kind: .document)]
    /// One entry per entered container node: true when it pushed a frame.
    private var pushed: [Bool] = []
    private var nestingDepth = 0
    /// 0-based line of the last block made. Used when cmark gives no line (0).
    private var lastLine: Int
    /// Added to every cmark line, for a chunk of a bigger text.
    private let lineOffset: Int

    var lastBlockLine: Int { lastLine }

    private var pieces: [Piece] = []
    private var links: [InlineLink] = []
    private var contexts = [InlineContext()]
    private var extensionKinds: [UInt32: ExtensionKind] = [:]
    private var source: SourceText

    init(source: SourceText, softBreak: MarkdownSoftBreak, lineOffset: Int = 0, lastLine: Int = 0) {
        self.source = source
        self.softBreak = softBreak
        self.lineOffset = lineOffset
        self.lastLine = lastLine
    }

    mutating func walk(_ root: UnsafeMutablePointer<cmark_node>) -> [ParsedBlock] {
        guard let iterator = cmark_iter_new(root) else { return [] }
        defer { cmark_iter_free(iterator) }
        while true {
            let event = cmark_iter_next(iterator)
            if event == CMARK_EVENT_DONE { break }
            guard let node = cmark_iter_get_node(iterator) else { continue }
            if event == CMARK_EVENT_ENTER {
                enter(node)
            } else if event == CMARK_EVENT_EXIT {
                exit(node)
            }
        }
        return frames[0].blocks
    }

    // MARK: Events

    private mutating func enter(_ node: UnsafeMutablePointer<cmark_node>) {
        let type = cmark_node_get_type(node)
        switch type {
        case CMARK_NODE_DOCUMENT:
            break
        case CMARK_NODE_BLOCK_QUOTE:
            pushContainer(Frame(kind: .quote), allowed: nestingDepth < CmarkParser.maxNestingDepth, nests: true)
        case CMARK_NODE_LIST:
            let isOrdered = cmark_node_get_list_type(node) == CMARK_ORDERED_LIST
            let start = isOrdered ? Int(cmark_node_get_list_start(node)) : 1
            pushContainer(Frame(kind: .list(isOrdered: isOrdered, start: start)), allowed: nestingDepth < CmarkParser.maxNestingDepth, nests: false)
        case CMARK_NODE_ITEM:
            let parentIsList: Bool
            if case .list = frames[frames.count - 1].kind { parentIsList = true } else { parentIsList = false }
            pushContainer(Frame(kind: .item(checkbox: taskCheckbox(of: node))), allowed: parentIsList, nests: true)
        case CMARK_NODE_PARAGRAPH, CMARK_NODE_HEADING:
            startLeaf()
        case CMARK_NODE_CODE_BLOCK:
            addCodeBlock(node)
        case CMARK_NODE_HTML_BLOCK:
            addHTMLBlock(node)
        case CMARK_NODE_THEMATIC_BREAK:
            addBlock(ParsedBlock(sourceLine: line(of: node), kind: .thematicBreak))
        case CMARK_NODE_TEXT:
            addPiece(literal(node), extra: [])
        case CMARK_NODE_CODE:
            addPiece(literal(node), extra: .code)
        case CMARK_NODE_HTML_INLINE:
            addPiece(literal(node), extra: .inlineHTML)
        case CMARK_NODE_SOFTBREAK:
            addPiece(softBreak == .lineBreak ? "\n" : " ", extra: .softBreak)
        case CMARK_NODE_LINEBREAK:
            addPiece("\n", extra: .lineBreak)
        case CMARK_NODE_EMPH:
            pushStyle(.emphasized)
        case CMARK_NODE_STRONG:
            pushStyle(.stronglyEmphasized)
        case CMARK_NODE_LINK:
            pushLink(node, isImage: false)
        case CMARK_NODE_IMAGE:
            pushLink(node, isImage: true)
        default:
            enterExtension(node, type: type)
        }
    }

    private mutating func exit(_ node: UnsafeMutablePointer<cmark_node>) {
        let type = cmark_node_get_type(node)
        switch type {
        case CMARK_NODE_BLOCK_QUOTE, CMARK_NODE_LIST:
            popContainer()
        case CMARK_NODE_ITEM:
            popContainer(itemLine: line(of: node))
        case CMARK_NODE_PARAGRAPH:
            finishParagraph(node)
        case CMARK_NODE_HEADING:
            let text = finishLeaf()
            // Foundation drops an empty heading (it has no text runs).
            guard !text.isEmpty else { return }
            addBlock(ParsedBlock(sourceLine: line(of: node), kind: .heading(level: Int(cmark_node_get_heading_level(node)), text: text)))
        case CMARK_NODE_IMAGE, CMARK_NODE_LINK:
            let context = contexts[contexts.count - 1]
            // Foundation shows an image with empty alt text as U+FFFC, so the image is not lost. The same
            // placeholder keeps a link with empty text, so `[](url)` does not vanish with its paragraph.
            if context.link >= 0, pieces.count == context.piecesBeforeImage {
                pieces.append(Piece(text: "\u{FFFC}", style: context.style.union(.placeholder), link: context.link))
            }
            if contexts.count > 1 { contexts.removeLast() }
        case CMARK_NODE_EMPH, CMARK_NODE_STRONG:
            if contexts.count > 1 { contexts.removeLast() }
        default:
            exitExtension(node, type: type)
        }
    }

    private mutating func enterExtension(_ node: UnsafeMutablePointer<cmark_node>, type: cmark_node_type) {
        switch extensionKind(node, type: type) {
        case .table:
            let count = Int(cmark_gfm_extensions_get_table_columns(node))
            pushContainer(Frame(kind: .table(columnCount: count, columns: Self.columns(node, count: count))), allowed: true, nests: false)
        case .tableRow:
            let isHeader = cmark_gfm_extensions_get_table_row_is_header(node) != 0
            pushContainer(Frame(kind: .tableRow(isHeader: isHeader), line: line(of: node)), allowed: true, nests: false)
        case .tableCell:
            startLeaf()
        case .strikethrough:
            pushStyle(.strikethrough)
        case .other:
            break
        }
    }

    private mutating func exitExtension(_ node: UnsafeMutablePointer<cmark_node>, type: cmark_node_type) {
        switch extensionKind(node, type: type) {
        case .table:
            popContainer(tableLine: line(of: node))
        case .tableRow:
            popContainer()
        case .tableCell:
            let text = finishLeaf()
            frames[frames.count - 1].cells.append(text)
        case .strikethrough:
            if contexts.count > 1 { contexts.removeLast() }
        case .other:
            break
        }
    }

    /// Extension node types have no public constants. Look each type up by name once.
    private mutating func extensionKind(_ node: UnsafeMutablePointer<cmark_node>, type: cmark_node_type) -> ExtensionKind {
        if let known = extensionKinds[type.rawValue] { return known }
        let name = cmark_node_get_type_string(node).map { String(cString: $0) } ?? ""
        let kind: ExtensionKind = switch name {
        case "table": .table
        case "table_row", "table_header": .tableRow
        case "table_cell": .tableCell
        case "strikethrough": .strikethrough
        default: .other
        }
        extensionKinds[type.rawValue] = kind
        return kind
    }

    // MARK: Containers

    private mutating func pushContainer(_ frame: Frame, allowed: Bool, nests: Bool) {
        pushed.append(allowed)
        guard allowed else { return }
        frames.append(frame)
        if nests { nestingDepth += 1 }
    }

    private mutating func popContainer(tableLine: Int = 0, itemLine: Int = 0) {
        guard let didPush = pushed.popLast(), didPush, frames.count > 1 else { return }
        let frame = frames.removeLast()
        switch frame.kind {
        case .document:
            break
        case .quote:
            nestingDepth -= 1
            // A quote with no content (for example only a link definition) is dropped, like Foundation.
            guard let line = frame.line else { return }
            addBlock(ParsedBlock(sourceLine: line, kind: .blockQuote(frame.blocks)))
        case .item(let checkbox):
            nestingDepth -= 1
            var blocks = frame.blocks
            var line = frame.line
            if blocks.isEmpty, checkbox != nil {
                // An empty task item keeps its checkbox. The editor writes `- [ ] ` for a new task.
                blocks = [ParsedBlock(sourceLine: itemLine, kind: .paragraph(InlineText()))]
                line = itemLine
            }
            let index = frames.count - 1
            if !blocks.isEmpty {
                if frames[index].firstKeptItem == nil {
                    frames[index].firstKeptItem = frames[index].itemCount
                    frames[index].line = line
                }
                frames[index].items.append(ParsedListItem(checkbox: checkbox, blocks: blocks))
            }
            frames[index].itemCount += 1
        case .list(let isOrdered, let start):
            guard let line = frame.line, !frame.items.isEmpty else { return }
            // Foundation numbers from the first item that has content.
            let startIndex = isOrdered ? start + (frame.firstKeptItem ?? 0) : 1
            addBlock(ParsedBlock(sourceLine: line, kind: .list(ParsedList(isOrdered: isOrdered, startIndex: startIndex, items: frame.items))))
        case .table(_, let columns):
            addBlock(ParsedBlock(sourceLine: tableLine, kind: .table(ParsedTable(columns: columns, header: frame.header, rows: frame.rows, rowLines: frame.rowLines))))
        case .tableRow(let isHeader):
            let index = frames.count - 1
            guard case .table(let count, _) = frames[index].kind else { return }
            var cells = Array(frame.cells.prefix(count))
            while cells.count < count { cells.append(InlineText()) }
            if isHeader {
                frames[index].header = cells
            } else if cells.allSatisfy(\.isEmpty) {
                // Foundation drops a body row with only empty cells (it has no text runs).
                return
            } else {
                frames[index].rows.append(cells)
                frames[index].rowLines.append(frame.line ?? lastLine)
            }
        }
    }

    /// Adds a finished block to the innermost quote, item or the document.
    private mutating func addBlock(_ block: ParsedBlock) {
        lastLine = block.sourceLine
        let index = frames.count - 1
        if frames[index].line == nil { frames[index].line = block.sourceLine }
        frames[index].blocks.append(block)
    }

    // MARK: Leaf blocks

    private mutating func addCodeBlock(_ node: UnsafeMutablePointer<cmark_node>) {
        var code = literal(node)
        // Foundation drops an empty code block (it has no text runs).
        guard !code.isEmpty else { return }
        while code.hasSuffix("\n") { code.removeLast() }
        let info = cmark_node_get_fence_info(node).map { String(cString: $0) } ?? ""
        addBlock(ParsedBlock(sourceLine: line(of: node), kind: .codeBlock(language: info.isEmpty ? nil : info, code: code)))
    }

    /// An HTML block is shown as raw text, marked `.blockHTML` like Foundation does.
    private mutating func addHTMLBlock(_ node: UnsafeMutablePointer<cmark_node>) {
        let html = literal(node)
        guard !html.allSatisfy(\.isWhitespace) else { return }
        var text = InlineText()
        text.append(html, style: .blockHTML)
        addBlock(ParsedBlock(sourceLine: line(of: node), kind: .paragraph(text)))
    }

    private mutating func finishParagraph(_ node: UnsafeMutablePointer<cmark_node>) {
        var text = finishLeaf()
        removeMissedTaskMarker(paragraph: node, text: &text)
        let line = line(of: node)
        if let image = Self.imageBlockKind(for: text) {
            addBlock(ParsedBlock(sourceLine: line, kind: image))
        } else if !text.isEmpty {
            addBlock(ParsedBlock(sourceLine: line, kind: .paragraph(text)))
        }
    }

    private mutating func startLeaf() {
        pieces.removeAll(keepingCapacity: true)
        links.removeAll()
        contexts = [InlineContext()]
    }

    private mutating func finishLeaf() -> InlineText {
        let text = Self.applyStyleTags(pieces, links: links)
        pieces.removeAll(keepingCapacity: true)
        links = []
        contexts = [InlineContext()]
        return text
    }

    // MARK: Inlines

    private mutating func addPiece(_ text: String, extra: InlineStyle) {
        let context = contexts[contexts.count - 1]
        // Foundation keeps no inner styles and no line breaks in image alt text.
        if context.inImage, extra.contains(.softBreak) || extra.contains(.lineBreak) { return }
        let style = context.inImage ? context.style : context.style.union(extra)
        pieces.append(Piece(text: text, style: style, link: context.link))
    }

    private mutating func pushStyle(_ style: InlineStyle) {
        var context = contexts[contexts.count - 1]
        if !context.inImage { context.style.insert(style) }
        contexts.append(context)
    }

    private mutating func pushLink(_ node: UnsafeMutablePointer<cmark_node>, isImage: Bool) {
        var context = contexts[contexts.count - 1]
        if context.inImage {
            // Foundation drops anything inside alt text. -1: a nested node never adds a placeholder.
            context.piecesBeforeImage = -1
            contexts.append(context)
            return
        }
        if isImage && context.link >= 0 {
            // Foundation drops an image URL inside a link. The alt text (or the placeholder) keeps the link.
            context.inImage = true
            context.piecesBeforeImage = pieces.count
            contexts.append(context)
            return
        }
        let url = cmark_node_get_url(node).map { String(cString: $0) } ?? ""
        let title = cmark_node_get_title(node).map { String(cString: $0) } ?? ""
        links.append(InlineLink(url: url, title: title))
        context.link = links.count - 1
        // Links and images both get a placeholder on exit when nothing was added in between.
        context.piecesBeforeImage = pieces.count
        if isImage {
            context.style.insert(.image)
            context.inImage = true
        }
        contexts.append(context)
    }

    // MARK: Task items

    /// cmark's `tasklist` extension finds a task item from the source line, so `\[x]` or `&#91;x&#93;` stay text.
    /// Its checked flag is true when `[x]` appears anywhere on the line, so the state is read from the marker itself.
    private mutating func taskCheckbox(of item: UnsafeMutablePointer<cmark_node>) -> MarkdownListItem.Checkbox? {
        guard let type = cmark_node_get_type_string(item), String(cString: type) == "tasklist",
              let start = source.offset(line: Int(cmark_node_get_start_line(item)), column: Int(cmark_node_get_start_column(item)))
        else { return nil }
        return source.taskMarker(at: source.offsetAfterListMarker(at: start))
    }

    /// `tasklist` finds a marker only when the line starts with the item's list marker. It misses `> - [x] a`
    /// and `- - [x] a`. There the marker is still text at the start of the item's first paragraph.
    private mutating func removeMissedTaskMarker(paragraph node: UnsafeMutablePointer<cmark_node>, text: inout InlineText) {
        let index = frames.count - 1
        // The innermost entered container must be this paragraph's item, still without a checkbox or blocks.
        guard pushed.last == true, case .item(checkbox: nil) = frames[index].kind, frames[index].blocks.isEmpty,
              let item = cmark_node_parent(node), cmark_node_get_type(item) == CMARK_NODE_ITEM,
              cmark_node_first_child(item) == node,
              cmark_node_get_start_line(item) == cmark_node_get_start_line(node),
              let firstRun = text.runs.first, firstRun.style.isEmpty, firstRun.link < 0, firstRun.end >= 3,
              text.text.utf8.first == UInt8(ascii: "["),
              let start = source.offset(line: Int(cmark_node_get_start_line(node)), column: Int(cmark_node_get_start_column(node))),
              let checkbox = source.taskMarker(at: start)
        else { return }
        // Only the separator spaces in the source go with the marker. A space from `&#32;` is content.
        // cmark drops trailing spaces before a line end, so the text can hold fewer than the source.
        let separator = source.separatorAfterTaskMarker(at: start)
        let bytes = Array(text.text.utf8.prefix(firstRun.end))
        var count = 3
        while count < bytes.count, count < 3 + separator.count, bytes[count] == 32 || bytes[count] == 9 { count += 1 }
        text.dropFirstBytes(count)
        // When the text starts on the next line, the break after the marker goes too, like for a found marker.
        if separator.endsLine, let breakRun = text.runs.first, !breakRun.style.isDisjoint(with: [.softBreak, .lineBreak]) {
            text.dropFirstBytes(breakRun.end)
        }
        frames[index].kind = .item(checkbox: checkbox)
    }

    // MARK: Helpers

    /// cmark lines are 1-based. A paragraph cut short by a table has 0, and the table after it
    /// starts at the paragraph's real line. With no line at all, the block before gives it.
    private func line(of node: UnsafeMutablePointer<cmark_node>) -> Int {
        var line = Int(cmark_node_get_start_line(node))
        if line == 0, let next = cmark_node_next(node) { line = Int(cmark_node_get_start_line(next)) }
        return line > 0 ? line - 1 + lineOffset : lastLine
    }

    private func literal(_ node: UnsafeMutablePointer<cmark_node>) -> String {
        cmark_node_get_literal(node).map { String(cString: $0) } ?? ""
    }
}
