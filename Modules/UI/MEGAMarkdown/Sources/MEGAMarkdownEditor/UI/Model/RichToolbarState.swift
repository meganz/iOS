import MEGAMarkdown

/// What the formatting toolbar and the key commands show for the current selection.
/// Equatable, so the model publishes a new value only when something the toolbar shows changed.
struct RichToolbarState: Equatable, Sendable {
    enum ListKind: Equatable, Sendable {
        case bullet
        case numbered
        case task
    }

    /// Inline styles that show as on. A link shows as `isLinkOn`, not here.
    var activeStyles: Set<RichSpanStyle> = []
    var isLinkOn = false
    /// False when the selection has no text block (code, divider or raw rows only).
    var canStyle = false
    /// True when the Link button works: text is selected in one row.
    var canEditLink = false
    /// The heading level of the selection's first row. nil for body text and other rows.
    var headingLevel: Int?
    /// The list kind of the selection's first row.
    var list: ListKind?
    var isQuote = false
    /// Tab on a list or quote row, when the model would move it. Off at the deepest visible nesting.
    var canIndent = false
    /// ⇧Tab on a list or quote row, when the model would move it.
    var canOutdent = false

    init() {}

    init(editor: RichEditor) {
        // One pass over the selection: it runs after every action, also after Select All.
        let summary = editor.selectionSummary
        activeStyles = summary.activeStyles.filter { !$0.isLink }
        isLinkOn = summary.activeStyles.contains { $0.isLink }
        canStyle = summary.hasText
        canEditLink = summary.hasText && editor.selection.isInOneBlock
        let index = editor.selection.start.blockIndex
        let block = editor.rows[index].block
        let above = index > 0 ? editor.rows[index - 1].block : nil
        headingLevel = editor.headingLevel(at: index)
        let isShallowEnough = Self.decorationCount(of: block) < MarkdownRowChrome.maxVisibleNesting
        switch block {
        case .listItem(let item, _):
            if item.isChecked != nil {
                list = .task
            } else {
                list = item.isOrdered ? .numbered : .bullet
            }
            // The model moves an item at most one level deeper than the item above it.
            if let aboveItem = above?.listItem {
                canIndent = isShallowEnough && item.indent <= aboveItem.indent
            }
            canOutdent = item.indent > 0
        case .quote(let depth, _):
            isQuote = true
            // A quote row goes at most one level deeper than the quote row above it, and never under depth 1.
            if case .quote(let aboveDepth, _)? = above {
                canIndent = isShallowEnough && depth <= aboveDepth
            }
            canOutdent = depth > 1
        default:
            break
        }
    }

    /// The chrome columns a row shows: one per list level up to the item, or one per quote level.
    /// The model keeps lists and quotes as flat rows, so a row never has both.
    static func decorationCount(of block: RichBlock) -> Int {
        switch block {
        case .listItem(let item, _): item.indent + 1
        case .quote(let depth, _): depth
        default: 0
        }
    }
}
