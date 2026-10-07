import Foundation

// MARK: - Typing

extension RichEditor {
    /// One text edit in a block: the range a text view replaces and the new text. Keys in one row form one undo step.
    /// A line break in `string` splits the block, like Enter or a multi-line insert.
    mutating func replaceText(inBlock blockIndex: Int, range: Range<Int>, with string: String) {
        guard rows.indices.contains(blockIndex) else { return }
        let block = rows[blockIndex].block
        if string.utf8.contains(where: { $0 == 10 || $0 == 13 }), block.richText != nil {
            select(.range(range, inBlock: blockIndex))
            insertText(string)
            return
        }
        let lower = block.clampedOffset(range.lowerBound)
        let upper = max(lower, block.clampedOffset(range.upperBound))
        let newBlock: RichBlock
        switch block {
        case .codeBlock(let language, let code):
            var newCode = code
            newCode.replaceUTF16(lower..<upper, with: string.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n"))
            newBlock = .codeBlock(language: language, code: newCode)
        case .paragraph, .heading, .listItem, .quote:
            guard let text = block.richText else { return }
            // Typing over a selection takes the style of its first character, like Notes.
            let styles = lower == upper ? typingStyles : text.styles(in: lower..<(lower + 1))
            newBlock = block.withText(text.replacing(lower..<upper, with: string, typingStyles: styles))
            setTypingStyles(styles)
        case .thematicBreak, .rawSource:
            insertParagraph(with: string, besideAtomicBlock: blockIndex, after: range.lowerBound > 0)
            return
        }
        guard newBlock != block else { return }
        let rowID = rows[blockIndex].id
        if undoStack.typingRowID == rowID {
            undoStack.continueTypingBurst()
        } else {
            undoStack.record(.init(range: blockIndex..<(blockIndex + 1), rows: [rows[blockIndex]], selection: selection, typingRowID: rowID))
        }
        updateBlock(at: blockIndex, to: newBlock)
        setSelectionWithoutStyleRefresh(.caret(RichPosition(blockIndex: blockIndex, offset: lower + string.utf16.count)))
    }

    /// Typing at a divider or raw block starts a new paragraph before it (caret offset 0) or after it.
    /// The paragraph and the keys typed into it after are one undo step.
    private mutating func insertParagraph(with string: String, besideAtomicBlock blockIndex: Int, after: Bool) {
        guard !string.isEmpty else { return }
        let index = after ? blockIndex + 1 : blockIndex
        var blocks = rows.map(\.block)
        blocks.insert(.paragraph(RichText(string)), at: index)
        commit(blocks, caret: RichPosition(blockIndex: index, offset: string.utf16.count))
        undoStack.markLastStepAsTyping(rowID: rows[index].id)
    }

    /// Inserts typed or dictated text at the selection. Each line after the first becomes a new block that
    /// continues the block kind (a list stays a list). The text is not read as Markdown: use `paste` for that.
    mutating func insertText(_ string: String) {
        let normalized = string.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if lines.count == 1, let range = selection.rangeInBlock {
            replaceText(inBlock: selection.start.blockIndex, range: range, with: normalized)
            return
        }
        if normalized == "\n" {
            insertParagraphBreak()
            return
        }
        var (document, caret) = self.document.deleting(selection)
        if case .codeBlock = document.blocks[caret.blockIndex] {
            (document, caret) = document.insertingCode(normalized, at: caret)
        } else {
            let styles = selection.isCaret ? typingStyles : []
            let paragraphs = lines.map { line in
                RichBlock.paragraph(RichText(line, spans: styles.map { RichSpan(range: 0..<line.utf16.count, style: $0) }))
            }
            (document, caret) = document.inserting(paragraphs, at: caret)
        }
        commit(document.blocks, caret: caret)
    }

    /// Enter. Replaces the selection, then splits the block at the caret.
    mutating func insertParagraphBreak() {
        let (deleted, caret) = document.deleting(selection)
        let (split, newCaret) = deleted.splitting(at: caret)
        commit(split.blocks, caret: newCaret)
    }

    /// Backspace: deletes the selection, the character before the caret, or the structure at a block start.
    mutating func deleteBackward() {
        guard selection.isCaret else {
            deleteSelection()
            return
        }
        let caret = selection.start
        let block = rows[caret.blockIndex].block
        if block.plainText == nil {
            // A caret after a divider or raw block (select mode): the block goes.
            guard caret.offset == 1 else { return }
            deleteSelection(RichSelection(start: RichPosition(blockIndex: caret.blockIndex, offset: 0), end: caret))
            return
        }
        if caret.offset == 0 {
            undoStack.endTypingBurst()
            guard let (document, position) = document.backspacingAtStart(of: caret.blockIndex) else { return }
            commit(document.blocks, caret: position)
            return
        }
        guard let text = block.plainText else { return }
        // A whole Character goes: an emoji with modifiers or a letter with its combining marks.
        let end = text.index(utf16Offset: caret.offset)
        let start = text.index(before: end)
        let lower = text.utf16.distance(from: text.utf16.startIndex, to: start)
        replaceText(inBlock: caret.blockIndex, range: lower..<caret.offset, with: "")
    }

    mutating func deleteSelection() {
        deleteSelection(selection)
    }

    private mutating func deleteSelection(_ range: RichSelection) {
        guard !range.isCaret else { return }
        let (document, caret) = document.deleting(range)
        commit(document.blocks, caret: caret)
    }

    /// The text view changed its text without announcing the range (dictation, some keyboards).
    /// `caret` is the caret after the change. It makes the edit range exact when letters repeat.
    mutating func didChangeText(inBlock blockIndex: Int, to newText: String, caret: Int? = nil) {
        guard rows.indices.contains(blockIndex), let oldText = rows[blockIndex].block.plainText, !oldText.hasSameBytes(as: newText) else { return }
        let edit = Self.editRange(old: oldText, new: newText, caret: caret)
        let inserted = newText.substring(utf16: edit.range.lowerBound..<(edit.range.lowerBound + edit.replacementLength))
        replaceText(inBlock: blockIndex, range: edit.range, with: inserted)
    }

    /// The UTF-16 range that changed between two strings, found by common prefix and suffix.
    /// With `caret` (the caret after the edit), the edit is taken to end at the caret. This picks the right
    /// place when letters repeat: typing "a" in "a|a" is at offset 1, not at the end.
    static func editRange(old: String, new: String, caret: Int? = nil) -> (range: Range<Int>, replacementLength: Int) {
        let oldUnits = Array(old.utf16)
        let newUnits = Array(new.utf16)
        if let caret, caret <= newUnits.count {
            let suffix = newUnits.count - caret
            if suffix <= oldUnits.count, oldUnits.suffix(suffix).elementsEqual(newUnits.suffix(suffix)) {
                let limit = min(caret, oldUnits.count - suffix)
                var prefix = 0
                while prefix < limit, oldUnits[prefix] == newUnits[prefix] {
                    prefix += 1
                }
                return Self.scalarEdges(old: oldUnits, newCount: newUnits.count, prefix: prefix, suffix: suffix)
            }
        }
        var prefix = 0
        while prefix < oldUnits.count, prefix < newUnits.count, oldUnits[prefix] == newUnits[prefix] {
            prefix += 1
        }
        var suffix = 0
        while suffix < oldUnits.count - prefix, suffix < newUnits.count - prefix,
              oldUnits[oldUnits.count - 1 - suffix] == newUnits[newUnits.count - 1 - suffix] {
            suffix += 1
        }
        return Self.scalarEdges(old: oldUnits, newCount: newUnits.count, prefix: prefix, suffix: suffix)
    }

    /// Moves the edit edges out of a surrogate pair. Two scalars can share a high or a low surrogate,
    /// and an edit that splits a pair would leave half a character.
    private static func scalarEdges(old: [UInt16], newCount: Int, prefix: Int, suffix: Int) -> (range: Range<Int>, replacementLength: Int) {
        var prefix = prefix
        var suffix = suffix
        if prefix > 0, UTF16.isLeadSurrogate(old[prefix - 1]) { prefix -= 1 }
        if suffix > 0, UTF16.isTrailSurrogate(old[old.count - suffix]) { suffix -= 1 }
        return (prefix..<(old.count - suffix), newCount - suffix - prefix)
    }
}
