/// What a row draws around its text: nothing, a list marker or quote bars. A row that keeps its shape
/// keeps its chrome, so typing in it needs no list update.
enum RichRowShape: Equatable, Sendable {
    case plain
    case listItem(isOrdered: Bool, indent: Int, isTask: Bool)
    case quote(depth: Int)

    init(block: RichBlock) {
        switch block {
        case .listItem(let item, _): self = .listItem(isOrdered: item.isOrdered, indent: item.indent, isTask: item.isChecked != nil)
        case .quote(let depth, _): self = .quote(depth: depth)
        default: self = .plain
        }
    }
}

/// What the row list must do after the model changed. Pure: it reads only the values passed in.
///
/// The version rule: the same version is a selection change; one more applies `lastChange`;
/// anything else (a missed change) reloads every row.
enum RichChangePlan: Equatable, Sendable {
    /// Only the selection moved. No row changed.
    case selectionOnly
    /// The user typed in the text view of `row`, and it already shows the text. No list update.
    case ownEdit(row: Int)
    /// Rows `oldRows` were replaced by `newRowCount` rows. The first `keptRows` rows keep their identity,
    /// so their cells are configured again in place.
    case replace(oldRows: Range<Int>, newRowCount: Int, keptRows: Int)
    case reloadAll

    /// The facts of one model change.
    struct Input: Sendable {
        /// The model version the list shows.
        var appliedVersion: Int
        var version: Int
        var lastChange: RichEditor.RowChange?
        /// The row whose text view made the change. That view already shows the new text.
        var typedRow: Int?
        /// Row identities of the old rows in `lastChange.oldRange`, as the list shows them.
        var oldIDs: [RichRowID]
        /// Row identities of the new rows, in `lastChange`'s new range.
        var newIDs: [RichRowID]
        /// Item counts of the same old and new rows. A raw row keeps its items only with the same count.
        var oldItemCounts: [Int]
        var newItemCounts: [Int]
        /// Shapes of the same old and new rows. Enter in an empty list item turns it into a paragraph in place.
        var oldShapes: [RichRowShape]
        var newShapes: [RichRowShape]
    }

    /// After the plan the list shows `input.version`, for every case. Typing also adds one to the version.
    static func make(_ input: Input) -> RichChangePlan {
        guard input.version != input.appliedVersion else { return .selectionOnly }
        guard input.version == input.appliedVersion + 1, let change = input.lastChange,
              input.oldIDs.count == change.oldRange.count, input.newIDs.count == change.newCount,
              input.oldItemCounts.count == input.oldIDs.count, input.newItemCounts.count == input.newIDs.count,
              input.oldShapes.count == input.oldIDs.count, input.newShapes.count == input.newIDs.count else {
            return .reloadAll
        }
        let keptRows = keptPrefix(input)
        if let row = input.typedRow, change.oldRange == row..<(row + 1), change.newCount == 1, keptRows == 1,
           input.oldShapes == input.newShapes {
            return .ownEdit(row: row)
        }
        return .replace(oldRows: change.oldRange, newRowCount: change.newCount, keptRows: keptRows)
    }

    /// Leading rows whose identity is the old identity at the same place, with the same item count.
    /// Undo puts back the old identities, so a restored row matches only where the list shows that identity.
    private static func keptPrefix(_ input: Input) -> Int {
        let limit = min(input.oldIDs.count, input.newIDs.count)
        var kept = 0
        while kept < limit, input.oldIDs[kept] == input.newIDs[kept], input.oldItemCounts[kept] == input.newItemCounts[kept] {
            kept += 1
        }
        return kept
    }
}
