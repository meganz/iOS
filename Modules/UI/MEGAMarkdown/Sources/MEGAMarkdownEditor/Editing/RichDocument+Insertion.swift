import Foundation

extension RichDocument {
    /// True when new content at a divider or raw block goes before it: the caret is at offset 0.
    /// Front matter counts only on the first line of a file, so nothing goes before it.
    func insertsBeforeAtomicBlock(at position: RichPosition) -> Bool {
        guard position.offset == 0 else { return false }
        if position.blockIndex == 0, case .rawSource(let source) = blocks.first, SourceLines(source).frontMatterEnd() > 0 {
            return false
        }
        return true
    }

    /// Inserts pasted blocks at a caret.
    ///
    /// In a text block:
    /// - A first pasted paragraph joins the text before the caret. Any other first block goes after it.
    /// - Later pasted paragraphs take the kind of a list item or quote target, so a list stays a list.
    ///   Every other pasted block keeps its kind. Pasted list items move to the target's indent.
    /// - The text after the caret joins the last pasted paragraph, or becomes its own block.
    ///
    /// In a code block the caller inserts plain text instead (`insertingCode`).
    /// At a divider or raw block the blocks go before (offset 0) or after it. They always go after front matter.
    func inserting(_ pasted: [RichBlock], at position: RichPosition) -> (RichDocument, RichPosition) {
        let position = clamped(position)
        guard !pasted.isEmpty, !blocks.isEmpty else { return (self, position) }
        let index = position.blockIndex
        let target = blocks[index]
        var result = self

        guard let text = target.richText else {
            let insertAt = insertsBeforeAtomicBlock(at: position) ? index : index + 1
            result.blocks.insert(contentsOf: pasted, at: insertAt)
            result.normalizeListIndents(in: insertAt..<(insertAt + pasted.count))
            let lastIndex = insertAt + pasted.count - 1
            return (result, RichPosition(blockIndex: lastIndex, offset: result.blocks[lastIndex].length))
        }

        let head = text.slice(0..<position.offset)
        let tail = text.slice(position.offset..<text.length)
        let targetIndent = target.listItem?.indent ?? 0
        let adoptsKind = target.listItem != nil || { if case .quote = target { true } else { false } }()
        var output: [RichBlock] = []
        var rest = pasted[...]
        // True when the last output block holds pasted paragraph text, so the tail joins it.
        var lastTakesTail = false
        var keepsTarget = true

        if case .paragraph(let first)? = rest.first {
            output.append(target.withText(head + first))
            rest = rest.dropFirst()
            lastTakesTail = true
        } else if !head.isEmpty {
            output.append(target.withText(head))
        } else {
            // Nothing before the caret: the pasted block takes the target's place.
            keepsTarget = false
        }
        for block in rest {
            switch block {
            case .paragraph(let pastedText):
                output.append(adoptsKind ? Self.continuation(of: target).withText(pastedText) : block)
                lastTakesTail = true
            case .listItem(var item, let itemText):
                item.indent += targetIndent
                output.append(.listItem(item, text: itemText))
                lastTakesTail = false
            default:
                output.append(block)
                lastTakesTail = false
            }
        }

        // The caret goes to the end of the pasted content, before the tail.
        var caret = RichPosition(blockIndex: index + output.count - 1, offset: output.last?.length ?? 0)
        if lastTakesTail, let last = output.last, let lastText = last.richText {
            output[output.count - 1] = last.withText(lastText + tail)
        } else if !tail.isEmpty {
            output.append(keepsTarget ? Self.continuation(of: target).withText(tail) : target.withText(tail))
        } else if output.last?.richText == nil, output.last?.codeText == nil {
            // After a divider or raw block there is no caret place, so an empty paragraph follows.
            output.append(.paragraph(RichText()))
            caret = RichPosition(blockIndex: index + output.count - 1, offset: 0)
        }
        result.blocks.replaceSubrange(index...index, with: output)
        result.handOffStartNumber(from: target, at: index)
        result.normalizeListIndents(in: index..<(index + output.count))
        return (result, caret)
    }

    /// Plain text into a code block. Code keeps "\n" line ends.
    func insertingCode(_ text: String, at position: RichPosition) -> (RichDocument, RichPosition) {
        let position = clamped(position)
        guard blocks.indices.contains(position.blockIndex), case .codeBlock(let language, let code) = blocks[position.blockIndex] else {
            return (self, position)
        }
        let inserted = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        var newCode = code
        newCode.replaceUTF16(position.offset..<position.offset, with: inserted)
        var result = self
        result.blocks[position.blockIndex] = .codeBlock(language: language, code: newCode)
        return (result, RichPosition(blockIndex: position.blockIndex, offset: position.offset + inserted.utf16.count))
    }

    /// A list item can be at most one level deeper than the list item before it, and at level 0 after any other block.
    /// Deeper items would write as top-level items and come back at another indent.
    mutating func normalizeListIndents(in range: Range<Int>) {
        var index = range.lowerBound
        while index < blocks.count {
            guard case .listItem(var item, let text) = blocks[index] else {
                if index >= range.upperBound { return }
                index += 1
                continue
            }
            let maxIndent = index > 0 ? (blocks[index - 1].listItem.map { $0.indent + 1 } ?? 0) : 0
            if item.indent > maxIndent {
                item.indent = maxIndent
                blocks[index] = .listItem(item, text: text)
            } else if index >= range.upperBound {
                return
            }
            index += 1
        }
    }
}
