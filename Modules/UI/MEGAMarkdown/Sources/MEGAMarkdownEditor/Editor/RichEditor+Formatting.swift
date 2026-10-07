import Foundation

// MARK: - Block structure

extension RichEditor {
    /// A toolbar block action (heading, list, quote, indent) on every block of the selection.
    mutating func apply(_ action: RichBlockAction) {
        let changed = document.applying(action, to: selection.touchedBlockIndexes)
        commitKeepingSelection(changed.blocks)
    }

    /// A tap on a task checkbox. The caret does not move.
    mutating func toggleCheckbox(at blockIndex: Int) {
        guard rows.indices.contains(blockIndex) else { return }
        commitKeepingSelection(document.togglingCheckbox(at: blockIndex).blocks)
    }

    /// 1...6 for a heading row, nil for any other row. The heading menu shows it.
    func headingLevel(at blockIndex: Int) -> Int? {
        guard rows.indices.contains(blockIndex), case .heading(let level, _) = rows[blockIndex].block else { return nil }
        return level
    }

    /// For edits that keep every row (no split or join): the selection stays where it is.
    private mutating func commitKeepingSelection(_ blocks: [RichBlock]) {
        let kept = selection
        commit(blocks, caret: kept.start)
        if !kept.isCaret {
            setSelectionWithoutStyleRefresh(kept)
        }
    }
}

// MARK: - Inline styles

/// The toolbar's view of the selection. See `RichEditor.selectionSummary`.
struct RichSelectionSummary: Equatable, Sendable {
    /// Styles on every selected character. At a caret: the typing styles.
    var activeStyles: Set<RichSpanStyle>
    /// The selection has at least one text block, so styles can apply.
    var hasText: Bool
}

extension RichEditor {
    /// The selected range of each text block in the selection. Code, divider and raw blocks have none.
    var selectedTextRanges: [(blockIndex: Int, range: Range<Int>)] {
        selection.blockIndexes.compactMap { index in
            guard let text = rows[index].block.richText else { return nil }
            let lower = index == selection.start.blockIndex ? selection.start.offset : 0
            let upper = index == selection.end.blockIndex ? selection.end.offset : text.length
            return (index, lower..<max(lower, upper))
        }
    }

    /// False when the selection has no text block. Every style mix can be saved, so text blocks take any style.
    /// Stops at the first text block.
    func canApply(_ style: RichSpanStyle) -> Bool {
        selectionSummary.hasText
    }

    /// The styles the toolbar shows as on. At a caret: the typing styles. Over a range: styles on every selected character.
    var activeStyles: Set<RichSpanStyle> {
        selectionSummary.activeStyles
    }

    /// What the toolbar shows for the selection, in one pass over the selected rows.
    /// The pass stops once no style is on every character seen so far, so a selection of mostly plain rows reads
    /// only a few rows. Only a selection where every row shares a style reads every row.
    var selectionSummary: RichSelectionSummary {
        if selection.isCaret {
            let hasText = rows[selection.start.blockIndex].block.richText != nil
            return RichSelectionSummary(activeStyles: hasText ? typingStyles : [], hasText: hasText)
        }
        var hasText = false
        var candidates: Set<RichSpanStyle>?
        for index in selection.blockIndexes {
            guard let text = rows[index].block.richText else { continue }
            let lower = index == selection.start.blockIndex ? selection.start.offset : 0
            let upper = index == selection.end.blockIndex ? selection.end.offset : text.length
            guard lower < upper else { continue }
            hasText = true
            if let current = candidates {
                if current.isEmpty { break }
                candidates = current.filter { text.isCovered(by: $0, lower..<upper) }
            } else {
                candidates = text.styles(in: lower..<upper)
            }
        }
        return RichSelectionSummary(activeStyles: candidates ?? [], hasText: hasText)
    }

    /// At a caret: turns the style on or off for typing. Over a range: removes it when every selected character
    /// has it, adds it otherwise. A link style replaces other links. One undo step.
    mutating func toggleStyle(_ style: RichSpanStyle) {
        guard canApply(style) else { return }
        if selection.isCaret {
            var styles = typingStyles
            if styles.contains(style) {
                styles.remove(style)
            } else {
                if style.isLink { styles = styles.filter { !$0.isLink } }
                styles.insert(style)
            }
            setTypingStyles(styles)
            return
        }
        let parts = selectedTextRanges.filter { !$0.range.isEmpty }
        let isOn = parts.allSatisfy { rows[$0.blockIndex].block.richText?.isCovered(by: style, $0.range) ?? false }
        var blocks = rows.map(\.block)
        for part in parts {
            guard let text = blocks[part.blockIndex].richText else { continue }
            let changed = isOn ? text.removingStyle(style, in: part.range) : text.addingStyle(style, in: part.range)
            blocks[part.blockIndex] = blocks[part.blockIndex].withText(changed)
        }
        let kept = selection
        commit(blocks, caret: kept.start)
        setSelectionWithoutStyleRefresh(kept)
    }
}
