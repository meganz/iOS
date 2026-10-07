import Foundation

/// Structural toolbar actions.
enum RichBlockAction: Equatable, Sendable {
    /// Heading level 1...6 (clamped), or nil or 0 for body. A list item or quote loses its marker.
    case setHeading(Int?)
    case toggleBulletList
    case toggleOrderedList
    case toggleTaskList
    case toggleQuote
    case indent
    case outdent
}

// Pure structural edits. Each returns the new document and where the caret goes.
extension RichDocument {
    /// Enter at `position`. Lists and quotes continue (a task restarts unchecked, no start number).
    /// Enter on an empty item or quote removes one level instead. Enter at a heading end starts a paragraph.
    /// Enter on an empty last line of a code block leaves the block.
    func splitting(at position: RichPosition) -> (RichDocument, RichPosition) {
        guard blocks.indices.contains(position.blockIndex) else { return (self, position) }
        let index = position.blockIndex
        var result = self
        let block = blocks[index]

        switch block {
        case .codeBlock(let language, let code):
            let offset = code.alignedUTF16Offset(position.offset)
            // Enter on an empty last line leaves the block: the empty line goes, and a paragraph starts after it.
            if offset == code.utf16.count, code.hasSuffix("\n") {
                result.blocks[index] = .codeBlock(language: language, code: String(code.dropLast()))
                result.blocks.insert(.paragraph(RichText()), at: index + 1)
                return (result, RichPosition(blockIndex: index + 1, offset: 0))
            }
            var newCode = code
            newCode.replaceUTF16(offset..<offset, with: "\n")
            result.blocks[index] = .codeBlock(language: language, code: newCode)
            return (result, RichPosition(blockIndex: index, offset: offset + 1))
        case .thematicBreak, .rawSource:
            // Before the block (offset 0) or after it: a new empty paragraph there.
            let insertAt = position.offset == 0 ? index : index + 1
            result.blocks.insert(.paragraph(RichText()), at: insertAt)
            return (result, RichPosition(blockIndex: index + 1, offset: 0))
        case .paragraph, .heading, .listItem, .quote:
            break
        }

        guard let text = block.richText else { return (self, position) }
        let offset = text.text.alignedUTF16Offset(position.offset)

        if text.isEmpty, let stepped = Self.removingOneLevel(block) {
            result.blocks[index] = stepped
            result.handOffStartNumber(from: block, at: index)
            return (result, RichPosition(blockIndex: index, offset: 0))
        }

        // Enter at the start of a non-empty block pushes the block down. It keeps its own properties.
        if offset == 0 && !text.isEmpty {
            var above = Self.continuation(of: block)
            if case .listItem(var item, let itemText) = block, item.startNumber != nil, case .listItem(var aboveItem, _) = above {
                aboveItem.startNumber = item.startNumber
                above = .listItem(aboveItem, text: RichText())
                item.startNumber = nil
                result.blocks[index] = .listItem(item, text: itemText)
            }
            if case .heading = block { above = .paragraph(RichText()) }
            result.blocks.insert(above, at: index)
            return (result, RichPosition(blockIndex: index + 1, offset: 0))
        }

        let head = text.slice(0..<offset)
        let tail = text.slice(offset..<text.length)
        var next = Self.continuation(of: block).withText(tail)
        if case .heading = block, tail.isEmpty {
            next = .paragraph(RichText())
        }
        result.blocks[index] = block.withText(head)
        result.blocks.insert(next, at: index + 1)
        return (result, RichPosition(blockIndex: index + 1, offset: 0))
    }

    /// Backspace at offset 0 of `blockIndex`. First removes structure (indent, quote depth, marker, heading),
    /// then joins the block into the text block before it. Deletes a divider before it.
    /// Returns nil when nothing changes.
    func backspacingAtStart(of blockIndex: Int) -> (RichDocument, RichPosition)? {
        guard blocks.indices.contains(blockIndex) else { return nil }
        var result = self
        let block = blocks[blockIndex]

        switch block {
        case .listItem, .quote, .heading:
            guard let stepped = Self.removingOneLevel(block) else { return nil }
            result.blocks[blockIndex] = stepped
            result.handOffStartNumber(from: block, at: blockIndex)
            return (result, RichPosition(blockIndex: blockIndex, offset: 0))
        case .codeBlock(_, let code):
            guard code.isEmpty else { return nil }
            result.blocks[blockIndex] = .paragraph(RichText())
            return (result, RichPosition(blockIndex: blockIndex, offset: 0))
        case .thematicBreak, .rawSource:
            return nil
        case .paragraph(let text):
            guard blockIndex > 0 else { return nil }
            let previousIndex = blockIndex - 1
            let previous = blocks[previousIndex]
            switch previous {
            case .thematicBreak:
                result.blocks.remove(at: previousIndex)
                return (result, RichPosition(blockIndex: previousIndex, offset: 0))
            case .codeBlock(_, let code):
                guard text.isEmpty else { return nil }
                result.blocks.remove(at: blockIndex)
                return (result, RichPosition(blockIndex: previousIndex, offset: code.utf16.count))
            case .rawSource:
                guard text.isEmpty else { return nil }
                result.blocks.remove(at: blockIndex)
                return (result, RichPosition(blockIndex: previousIndex, offset: 1))
            case .paragraph, .heading, .listItem, .quote:
                guard let previousText = previous.richText else { return nil }
                result.blocks[previousIndex] = previous.withText(previousText + text)
                result.blocks.remove(at: blockIndex)
                return (result, RichPosition(blockIndex: previousIndex, offset: previousText.length))
            }
        }
    }

    /// The action on every text block from `blockIndexes`. The first text block decides on or off for a toggle,
    /// so a mixed selection turns all blocks the same way. Indent and outdent move list items with their children.
    func applying(_ action: RichBlockAction, to blockIndexes: ClosedRange<Int>) -> RichDocument {
        let indexes = blockIndexes.clamped(to: 0...max(0, blocks.count - 1))
        guard !blocks.isEmpty, let first = indexes.first(where: { blocks[$0].richText != nil }) else { return self }
        switch action {
        case .indent, .outdent:
            return shiftingLevel(of: indexes, by: action == .indent ? 1 : -1)
        default:
            let turnsOff = Self.isOn(action, blocks[first])
            var result = self
            for index in indexes {
                result.apply(action, turningOff: turnsOff, at: index)
            }
            return result
        }
    }

    func togglingCheckbox(at blockIndex: Int) -> RichDocument {
        guard blocks.indices.contains(blockIndex), case .listItem(var item, let text) = blocks[blockIndex],
              let checked = item.isChecked else { return self }
        item.isChecked = !checked
        var result = self
        result.blocks[blockIndex] = .listItem(item, text: text)
        return result
    }

    // MARK: - Helpers

    private static func isOn(_ action: RichBlockAction, _ block: RichBlock) -> Bool {
        switch action {
        case .toggleBulletList: block.listItem.map { !$0.isOrdered && $0.isChecked == nil } ?? false
        case .toggleOrderedList: block.listItem?.isOrdered ?? false
        case .toggleTaskList: block.listItem?.isChecked != nil
        case .toggleQuote: if case .quote = block { true } else { false }
        case .setHeading, .indent, .outdent: false
        }
    }

    private mutating func apply(_ action: RichBlockAction, turningOff: Bool, at index: Int) {
        let block = blocks[index]
        guard let text = block.richText else { return }
        let indent = block.listItem?.indent ?? 0
        let newBlock: RichBlock
        switch action {
        case .setHeading(let level):
            // Markdown has 6 levels. Anything below 1 means body.
            newBlock = if let level, level >= 1 { .heading(level: min(level, 6), text: text) } else { .paragraph(text) }
        case .toggleBulletList:
            newBlock = turningOff ? .paragraph(text) : .listItem(RichListItem(isOrdered: false, indent: indent), text: text)
        case .toggleOrderedList:
            newBlock = turningOff ? .paragraph(text) : .listItem(RichListItem(isOrdered: true, indent: indent), text: text)
        case .toggleTaskList:
            // A task is always a bullet item (`- [ ]`), like GitHub and Android.
            let checked = block.listItem?.isChecked ?? false
            newBlock = turningOff ? .paragraph(text) : .listItem(RichListItem(isOrdered: false, indent: indent, isChecked: checked), text: text)
        case .toggleQuote:
            newBlock = turningOff ? .paragraph(text) : .quote(depth: 1, text: text)
        case .indent, .outdent:
            return
        }
        guard newBlock != block else { return }
        blocks[index] = newBlock
        handOffStartNumber(from: block, at: index)
    }

    /// When the first item of an ordered run leaves the run, the next item of that run takes its start number,
    /// so `5. a 6. b` keeps counting from 5. `blocks[index]` is the block after the change, `old` the one before.
    mutating func handOffStartNumber(from old: RichBlock, at index: Int) {
        guard case .listItem(let oldItem, _) = old, oldItem.isOrdered, let start = oldItem.startNumber else { return }
        if case .listItem(let newItem, _) = blocks[index], newItem.isOrdered, newItem.indent == oldItem.indent { return }
        var next = index + 1
        while next < blocks.count, case .listItem(let item, let text) = blocks[next] {
            if item.indent > oldItem.indent {
                next += 1
                continue
            }
            if item.indent == oldItem.indent, item.isOrdered, item.startNumber == nil {
                var moved = item
                moved.startNumber = start
                blocks[next] = .listItem(moved, text: text)
            }
            return
        }
    }

    /// The block a split creates after `block`.
    static func continuation(of block: RichBlock) -> RichBlock {
        switch block {
        case .listItem(var item, _):
            item.startNumber = nil
            if item.isChecked != nil { item.isChecked = false }
            return .listItem(item, text: RichText())
        case .quote(let depth, _):
            return .quote(depth: depth, text: RichText())
        case .heading(let level, _):
            return .heading(level: level, text: RichText())
        default:
            return .paragraph(RichText())
        }
    }

    /// One level less structure: indent, then quote depth, then the marker or heading.
    private static func removingOneLevel(_ block: RichBlock) -> RichBlock? {
        switch block {
        case .listItem(var item, let text):
            if item.indent > 0 {
                item.indent -= 1
                return .listItem(item, text: text)
            }
            return .paragraph(text)
        case .quote(let depth, let text):
            return depth > 1 ? .quote(depth: depth - 1, text: text) : .paragraph(text)
        case .heading(_, let text):
            return .paragraph(text)
        default:
            return nil
        }
    }

    /// Indent or outdent the list items in `indexes` with the deeper items after them, or the quote rows.
    /// A list item goes at most one level deeper than the item above the range. Nothing moves when a row cannot.
    private func shiftingLevel(of indexes: ClosedRange<Int>, by step: Int) -> RichDocument {
        var result = self
        if let firstItem = blocks[indexes.lowerBound].listItem {
            var end = indexes.upperBound + 1
            let lastIndent = blocks[indexes.upperBound].listItem?.indent ?? firstItem.indent
            while end < blocks.count, let item = blocks[end].listItem, item.indent > lastIndent { end += 1 }
            let items = (indexes.lowerBound..<end).compactMap { blocks[$0].listItem }
            guard items.count == end - indexes.lowerBound else { return self }
            if step < 0 {
                guard firstItem.indent > 0 else { return self }
            } else {
                guard indexes.lowerBound > 0, let above = blocks[indexes.lowerBound - 1].listItem,
                      firstItem.indent + 1 <= above.indent + 1 else { return self }
            }
            for index in indexes.lowerBound..<end {
                guard case .listItem(var item, let text) = blocks[index] else { continue }
                item.indent = max(0, item.indent + step)
                result.blocks[index] = .listItem(item, text: text)
            }
            return result
        }
        for index in indexes {
            guard case .quote(let depth, let text) = blocks[index] else { return self }
            let newDepth = depth + step
            guard newDepth >= 1 else { return self }
            if step > 0, index == indexes.lowerBound {
                guard index > 0, case .quote(let aboveDepth, _) = blocks[index - 1], newDepth <= aboveDepth + 1 else { return self }
            }
            result.blocks[index] = .quote(depth: newDepth, text: text)
        }
        return result
    }
}
