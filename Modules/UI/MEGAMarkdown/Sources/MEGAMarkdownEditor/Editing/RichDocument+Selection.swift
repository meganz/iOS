import Foundation

// Edits over a selection that can span blocks. Copy, cut, paste and select mode use them.
extension RichDocument {
    /// The selected content as blocks. The end blocks are cut at the selection and keep their kind.
    /// A divider or raw block at an end is in when the selection covers it (see `RichBlock.length`).
    /// An ordered item keeps the number it shows, so `3. c` copies as `3. c`.
    func fragment(in selection: RichSelection) -> [RichBlock] {
        let selection = clamped(selection)
        guard !selection.isCaret, !blocks.isEmpty else { return [] }
        let numbers = orderedNumbers()
        var result: [RichBlock] = []
        var shownNumbers: [Int?] = []
        for index in selection.blockIndexes {
            let lower = index == selection.start.blockIndex ? selection.start.offset : 0
            let upper = index == selection.end.blockIndex ? selection.end.offset : blocks[index].length
            guard let piece = Self.piece(of: blocks[index], in: lower..<upper) else { continue }
            result.append(piece)
            shownNumbers.append(numbers[index])
        }
        // The fragment counts its runs from 1. The first item of a run that showed another number gets it as its
        // start number. Later items of the run then count up from it, so they need none.
        var runs: [Int: (isOrdered: Bool, number: Int)] = [:]
        for index in result.indices {
            guard case .listItem(var item, let text) = result[index] else {
                runs.removeAll()
                continue
            }
            runs = runs.filter { $0.key <= item.indent }
            var number = item.startNumber ?? 1
            if item.startNumber == nil, let run = runs[item.indent], run.isOrdered == item.isOrdered {
                number = run.number + 1
            }
            if item.isOrdered, let shown = shownNumbers[index], shown != number {
                item.startNumber = shown
                result[index] = .listItem(item, text: text)
                number = shown
            }
            runs[item.indent] = (item.isOrdered, number)
        }
        return result
    }

    /// The part of one block in `range`. nil when nothing of it is selected.
    private static func piece(of block: RichBlock, in range: Range<Int>) -> RichBlock? {
        switch block {
        case .codeBlock(let language, let code):
            guard !range.isEmpty || code.isEmpty else { return nil }
            return .codeBlock(language: language, code: code.substring(utf16: range))
        case .thematicBreak, .rawSource:
            return range.isEmpty ? nil : block
        case .paragraph, .heading, .listItem, .quote:
            guard let text = block.richText, !range.isEmpty || text.isEmpty else { return nil }
            return block.withText(text.slice(range))
        }
    }

    /// Removes the selected content. Two text blocks at the ends join into the first one, which keeps its kind.
    func deleting(_ selection: RichSelection) -> (RichDocument, RichPosition) {
        let selection = clamped(selection)
        guard !selection.isCaret, !blocks.isEmpty else { return (self, selection.start) }
        let first = selection.start.blockIndex
        let last = selection.end.blockIndex
        var result = self

        if first == last {
            let range = selection.start.offset..<selection.end.offset
            switch blocks[first] {
            case .codeBlock(let language, let code):
                var newCode = code
                newCode.replaceUTF16(range, with: "")
                result.blocks[first] = .codeBlock(language: language, code: newCode)
            case .thematicBreak, .rawSource:
                result.blocks.remove(at: first)
                return result.withAtLeastOneBlock(caret: RichPosition(blockIndex: first, offset: 0))
            case .paragraph, .heading, .listItem, .quote:
                guard let text = blocks[first].richText else { break }
                result.blocks[first] = blocks[first].withText(text.replacing(range, with: ""))
            }
            return (result, selection.start)
        }

        let head = Self.head(of: blocks[first], to: selection.start.offset)
        let tail = Self.tail(of: blocks[last], from: selection.end.offset)
        var joined: [RichBlock] = []
        var caret = RichPosition(blockIndex: first, offset: selection.start.offset)
        switch (head, tail) {
        case let (head?, tail?):
            if let headText = head.richText, let tailText = tail.richText {
                joined = [head.withText(headText + tailText)]
            } else if case .codeBlock(let language, let headCode) = head, case .codeBlock(_, let tailCode) = tail {
                joined = [.codeBlock(language: language, code: headCode + tailCode)]
            } else {
                joined = [head]
                // An empty end of a text block is not kept: the head already holds the caret.
                if tail.plainText?.isEmpty != true || tail.isRawSource { joined.append(tail) }
            }
        case let (head?, nil):
            joined = [head]
        case let (nil, tail?):
            joined = [tail]
            caret = RichPosition(blockIndex: first, offset: 0)
        case (nil, nil):
            caret = RichPosition(blockIndex: first, offset: 0)
        }
        result.blocks.replaceSubrange(first...last, with: joined)
        if joined.isEmpty {
            return result.withAtLeastOneBlock(caret: caret)
        }
        return (result, caret)
    }

    /// What stays of the first selected block. nil when the whole block goes.
    private static func head(of block: RichBlock, to offset: Int) -> RichBlock? {
        switch block {
        case .codeBlock(let language, let code):
            .codeBlock(language: language, code: code.substring(utf16: 0..<offset))
        case .thematicBreak, .rawSource:
            offset == 0 ? nil : block
        case .paragraph, .heading, .listItem, .quote:
            block.richText.map { block.withText($0.slice(0..<offset)) }
        }
    }

    /// What stays of the last selected block. nil when the whole block goes.
    private static func tail(of block: RichBlock, from offset: Int) -> RichBlock? {
        switch block {
        case .codeBlock(let language, let code):
            .codeBlock(language: language, code: code.substring(utf16: offset..<code.utf16.count))
        case .thematicBreak, .rawSource:
            offset == 0 ? block : nil
        case .paragraph, .heading, .listItem, .quote:
            block.richText.map { block.withText($0.slice(offset..<$0.length)) }
        }
    }

    /// The editor always has a block to type in.
    private func withAtLeastOneBlock(caret: RichPosition) -> (RichDocument, RichPosition) {
        guard blocks.isEmpty else { return (self, clamped(caret)) }
        var result = self
        result.blocks = [.paragraph(RichText())]
        return (result, RichPosition(blockIndex: 0, offset: 0))
    }
}
