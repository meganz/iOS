import Foundation

/// What a row draws around its content: quote bars, list marker columns and the space below.
/// Plain values, so any row list can build it from its own rows.
package struct MarkdownRowChrome: Equatable, Sendable {
    /// Deeper decorations get no more indent. A "…" marker shows that levels are hidden.
    /// `quoteTops` and `quoteBottoms` have one bit per visible level, so this is at most 8.
    package static let maxVisibleNesting = 8

    /// Outermost first.
    package var decorations: [MarkdownRowDecoration]
    package var gapBelow: MarkdownRowGap
    /// Innermost decoration columns that end above the gap below. The gap between two list items sits
    /// below their markers, like the spacing of the whole list, so a tall checkbox does not hide it.
    package var gapOutsideColumns: UInt8
    /// One bit per visible decoration level: a quote starts (`quoteTops`) or ends (`quoteBottoms`) in this row.
    /// Only there the bar has round corners, so a quote split over many rows shows one solid bar.
    package var quoteTops: UInt8
    package var quoteBottoms: UInt8

    package init(
        decorations: [MarkdownRowDecoration] = [],
        gapBelow: MarkdownRowGap = .none,
        gapOutsideColumns: UInt8 = 0,
        quoteTops: UInt8 = 0,
        quoteBottoms: UInt8 = 0
    ) {
        self.decorations = decorations
        self.gapBelow = gapBelow
        self.gapOutsideColumns = gapOutsideColumns
        self.quoteTops = quoteTops
        self.quoteBottoms = quoteBottoms
    }

    /// The visible decoration column that ends above the gap below, or nil when the gap sits below the content.
    package var gapColumn: Int? {
        let enclosing = decorations.count - Int(gapOutsideColumns)
        return enclosing < min(decorations.count, Self.maxVisibleNesting) ? enclosing : nil
    }

    /// Whether the quote bar at decoration `level` rounds its top and bottom corners in this row.
    /// Levels from `maxVisibleNesting` on have no bit, so their bars never round.
    package func quoteBarEnds(level: Int) -> (top: Bool, bottom: Bool) {
        guard level >= 0, level < Self.maxVisibleNesting else { return (false, false) }
        let bit = UInt8(1) << level
        return (quoteTops & bit != 0, quoteBottoms & bit != 0)
    }

    /// Space below the row. `outer` sits below the whole row, outside the quote bars.
    /// `inner` sits inside the decoration columns, so the bars do not break between rows.
    package func gapSpacing(blockSpacing: CGFloat, nestedSpacing: CGFloat) -> (outer: CGFloat, inner: CGFloat) {
        switch gapBelow {
        case .block: (blockSpacing, 0)
        case .nested: (0, nestedSpacing)
        case .betweenItems(let taskItems): (0, CGFloat(taskItems) * ListBlockView.taskItemPadding)
        case .none: (0, 0)
        }
    }
}

/// One column in front of a row's content.
package enum MarkdownRowDecoration: Equatable, Sendable {
    case quote
    /// A list item column. The marker is drawn on the item's first row and hidden (kept for its width) on later rows.
    case listItem(MarkdownListMarker, showsMarker: Bool)
}

/// The marker of a list item. A checkbox has no label here: the row's own text is its label.
package enum MarkdownListMarker: Equatable, Sendable {
    case bullet
    /// The item's number in the whole list, not in a split part.
    case number(Int)
    case checkbox(isChecked: Bool)

    package var isCheckbox: Bool {
        if case .checkbox = self { true } else { false }
    }
}

/// Space below a row.
package enum MarkdownRowGap: Equatable, Sendable {
    /// Between top-level blocks.
    case block
    /// Between blocks inside a list item or quote.
    case nested
    /// Between two items of one list. `taskItems` (0, 1 or 2) counts the task items next to the gap.
    /// Each task item pads its side, like `ListBlockView`.
    case betweenItems(taskItems: Int)
    /// Between parts of one split block.
    case none
}
