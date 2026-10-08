import MEGAMarkdown

/// The chrome (quote bars, list markers, gaps) of every rich row, the same as the preview draws for the same Markdown.
///
/// The model keeps lists and quotes as flat rows with an indent or a depth. The preview builds its chrome
/// from nested blocks (`PreviewRows.Builder`). This index rebuilds the nesting with one stack per row:
/// - a list item at indent n sits in lists 0...n and items 0...n. An item continues the list at its indent
///   when the kind matches and it does not start a new numbered run, like the exporter writes it;
/// - a quote row at depth d sits in quotes 0..<d. Neighbour quote rows share their outer quotes.
/// The gap below a row then follows from the deepest container it shares with the next row.
struct RichChromeIndex: Equatable, Sendable {
    private(set) var chromes: [MarkdownRowChrome] = []

    init() {}

    init(blocks: some Collection<RichBlock>, numbers: [Int?]) {
        chromes = Self.build(blocks, numbers: numbers)
    }

    subscript(row: Int) -> MarkdownRowChrome {
        chromes[row]
    }

    var count: Int { chromes.count }

    /// Updates the index after `change`. `blocks` are the rows after the change.
    /// Lists, quotes and number runs end at a plain row (neither a list item nor a quote). So only the rows
    /// between the plain rows around the change are built again, with their numbers: O(that run).
    /// Returns the rows outside the change whose chrome changed (new indexes), for example renumbered items.
    /// After a full build it returns nil: any row can have changed.
    @discardableResult
    mutating func apply<Blocks: RandomAccessCollection<RichBlock>>(
        _ change: RichEditor.RowChange,
        blocks: Blocks
    ) -> [Int]? where Blocks.Index == Int {
        let newRange = change.oldRange.lowerBound..<(change.oldRange.lowerBound + change.newCount)
        guard change.oldRange.upperBound <= chromes.count, newRange.upperBound <= blocks.count,
              blocks.count == chromes.count - change.oldRange.count + change.newCount else {
            chromes = Self.build(blocks, numbers: RichDocument.orderedNumbers(of: blocks))
            return nil
        }
        var start = newRange.lowerBound
        while start > 0, !Self.isPlain(blocks[start - 1]) { start -= 1 }
        var end = newRange.upperBound
        while end < blocks.count, !Self.isPlain(blocks[end]) { end += 1 }
        let run = blocks[start..<end]
        var fresh = Self.build(run, numbers: RichDocument.orderedNumbers(of: run))
        // The plain row after the run is a new top-level block.
        if end < blocks.count, !fresh.isEmpty { fresh[fresh.count - 1].gapBelow = .block }
        let oldEnd = end - newRange.count + change.oldRange.count
        let old = chromes[start..<oldEnd]
        chromes.replaceSubrange(start..<oldEnd, with: fresh)
        var changed: [Int] = []
        for row in start..<end where !newRange.contains(row) {
            let oldRow = row < newRange.lowerBound ? row : row - newRange.count + change.oldRange.count
            if old[oldRow] != chromes[row] { changed.append(row) }
        }
        if start > 0 {
            let gap = start < chromes.count ? MarkdownRowGap.block : Self.lastRowGap
            if chromes[start - 1].gapBelow != gap {
                chromes[start - 1].gapBelow = gap
                changed.insert(start - 1, at: 0)
            }
        }
        return changed
    }

    private static func isPlain(_ block: RichBlock) -> Bool {
        switch block {
        case .listItem, .quote: false
        default: true
        }
    }

    // MARK: - Build

    /// The gap the preview leaves below its last row: none is set, so it keeps the default.
    private static let lastRowGap = MarkdownRowChrome().gapBelow

    /// One open container on the path of a row. Lists draw nothing. Items and quotes draw one decoration column.
    private struct Container: Equatable {
        enum Kind: Equatable {
            case list(isOrdered: Bool)
            case item(MarkdownListMarker, isTask: Bool)
            case quote
        }

        let id: Int
        let kind: Kind

        var isDecoration: Bool {
            if case .list = kind { false } else { true }
        }
    }

    static func build(_ blocks: some Collection<RichBlock>, numbers: [Int?]) -> [MarkdownRowChrome] {
        var chromes: [MarkdownRowChrome] = []
        chromes.reserveCapacity(blocks.count)
        var path: [Container] = []
        var nextID = 0
        for (row, block) in blocks.enumerated() {
            let newPath = Self.path(of: block, number: numbers[row], after: path, nextID: &nextID)
            let shared = zip(path, newPath).prefix { $0.0.id == $0.1.id }.count
            if row > 0 {
                setGap(below: row - 1, in: &chromes, oldPath: path, newPath: newPath, shared: shared)
            }
            var chrome = MarkdownRowChrome()
            chrome.decorations = Self.decorations(of: newPath)
            // A quote opened at this row starts its bar here.
            for (level, container) in Self.quoteLevels(of: newPath) where level < MarkdownRowChrome.maxVisibleNesting {
                if !path.contains(where: { $0.id == container.id }) { chrome.quoteTops |= UInt8(1) << level }
            }
            chromes.append(chrome)
            path = newPath
        }
        if let last = chromes.indices.last {
            for (level, _) in Self.quoteLevels(of: path) where level < MarkdownRowChrome.maxVisibleNesting {
                chromes[last].quoteBottoms |= UInt8(1) << level
            }
        }
        return chromes
    }

    /// The gap below the row before, its gap columns and the quote bars that end there.
    private static func setGap(below row: Int, in chromes: inout [MarkdownRowChrome], oldPath: [Container], newPath: [Container], shared: Int) {
        for (level, container) in quoteLevels(of: oldPath) where level < MarkdownRowChrome.maxVisibleNesting {
            if !newPath.prefix(shared).contains(where: { $0.id == container.id }) { chromes[row].quoteBottoms |= UInt8(1) << level }
        }
        guard shared > 0 else {
            // A new top-level block.
            chromes[row].gapBelow = .block
            return
        }
        let enclosing = newPath.prefix(shared).filter(\.isDecoration).count
        chromes[row].gapOutsideColumns = UInt8(clamping: chromes[row].decorations.count - enclosing)
        switch newPath[shared - 1].kind {
        case .list:
            // A new item of the same list. The item before is the sibling at the same place in the old path.
            let previousTask = if case .item(_, let isTask) = oldPath[shared].kind { isTask } else { false }
            let currentTask = if case .item(_, let isTask) = newPath[shared].kind { isTask } else { false }
            chromes[row].gapBelow = .betweenItems(taskItems: (previousTask ? 1 : 0) + (currentTask ? 1 : 0))
        case .item, .quote:
            // A later block inside the same item or quote.
            chromes[row].gapBelow = .nested
        }
    }

    /// The containers of `block`, reusing those of the row before that it continues.
    private static func path(of block: RichBlock, number: Int?, after previous: [Container], nextID: inout Int) -> [Container] {
        func make(_ kind: Container.Kind) -> Container {
            defer { nextID += 1 }
            return Container(id: nextID, kind: kind)
        }
        switch block {
        case .listItem(let item, _):
            // Lists before this row: two containers per level. Only a list row continues them.
            let previousLevels = previous.first.map { if case .list = $0.kind { previous.count / 2 } else { 0 } } ?? 0
            let level = min(item.indent, previousLevels)
            var path = Array(previous.prefix(level * 2))
            let marker: MarkdownListMarker = if let isChecked = item.isChecked {
                .checkbox(isChecked: isChecked)
            } else if item.isOrdered {
                .number(number ?? 1)
            } else {
                .bullet
            }
            let startsRun = item.isOrdered && item.startNumber != nil
            if level < previousLevels, previous[level * 2].kind == .list(isOrdered: item.isOrdered), !startsRun {
                path.append(previous[level * 2])
            } else {
                path.append(make(.list(isOrdered: item.isOrdered)))
            }
            path.append(make(.item(marker, isTask: item.isChecked != nil)))
            return path
        case .quote(let depth, _):
            let previousDepth = previous.first.map { if case .quote = $0.kind { previous.count } else { 0 } } ?? 0
            var path = Array(previous.prefix(min(depth, previousDepth)))
            while path.count < depth { path.append(make(.quote)) }
            return path
        default:
            return []
        }
    }

    /// Ancestor items hide their marker: only the item's own row shows it.
    private static func decorations(of path: [Container]) -> [MarkdownRowDecoration] {
        let lastItem = path.lastIndex { if case .item = $0.kind { true } else { false } }
        return path.indices.compactMap { index in
            switch path[index].kind {
            case .list: nil
            case .quote: .quote
            case .item(let marker, _): .listItem(marker, showsMarker: index == lastItem)
            }
        }
    }

    /// The quotes of a path with their decoration level.
    private static func quoteLevels(of path: [Container]) -> [(level: Int, container: Container)] {
        path.filter(\.isDecoration).enumerated().compactMap { level, container in
            container.kind == .quote ? (level, container) : nil
        }
    }
}
