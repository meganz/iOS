import Foundation
@testable import MEGAMarkdown
// Only for the underline attribute key.
import SwiftUI

/// TEST ONLY. The old Foundation parser (`AttributedString(markdown:)`), kept as the reference
/// the cmark parser is compared with. Copied from `MarkdownParser.swift` before the switch.
enum FoundationReferenceParser {
    static func parse(
        _ markdown: String,
        baseURL: URL? = nil,
        softBreak: MarkdownSoftBreak = .lineBreak
    ) -> MarkdownDocument {
        var options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        options.appliesSourcePositionAttributes = true
        guard let attributed = try? AttributedString(markdown: markdown, options: options, baseURL: baseURL) else {
            // Foundation failed: show the raw text so the user still sees the content.
            return MarkdownDocument(blocks: [MarkdownBlock(id: 0, sourceLine: 0, kind: .paragraph(AttributedString(markdown)))])
        }
        var builder = TreeBuilder(source: markdown, softBreak: softBreak)
        let root = builder.build(from: attributed)
        var converter = BlockConverter()
        return MarkdownDocument(blocks: converter.blocks(from: root.children))
    }
}

// MARK: - Step 1: runs -> intent tree

/// A node in the raw tree. One node per `PresentationIntent` identity.
private final class IntentNode {
    let identity: Int
    /// nil for the root and for HTML blocks (Foundation gives them no presentation intent).
    let kind: PresentationIntent.Kind?
    var line: Int?
    var text = AttributedString()
    var children: [IntentNode] = []
    var hasImage = false
    var hasNonImageText = false

    init(identity: Int, kind: PresentationIntent.Kind?, line: Int?) {
        self.identity = identity
        self.kind = kind
        self.line = line
    }
}

/// What one leaf block's inline runs contain: images, soft breaks, source lines and inline style tags.
private struct LeafScan {
    var hasImage = false
    var hasNonImageText = false
    var hasSoftBreak = false
    /// 0-based.
    var firstLine: Int?
    /// 0-based.
    var endLine: Int?
    var tags: [StyleTag] = []

    init(_ source: AttributedSubstring) {
        for (index, run) in source.runs.enumerated() {
            if run.imageURL != nil && run.link == nil {
                hasImage = true
            } else {
                hasNonImageText = true
            }
            if let position = run.markdownSourcePosition {
                if firstLine == nil { firstLine = position.startLine - 1 }
                endLine = position.endLine - 1
            }
            guard let inline = run.inlinePresentationIntent else { continue }
            if inline.contains(.softBreak) { hasSoftBreak = true }
            if inline.contains(.inlineHTML) {
                tags += StyleTag.tags(in: String(source[run.range].characters), run: index)
            }
        }
        StyleTag.markMatchedPairs(&tags)
    }
}

/// Walks the runs in order. Runs of one block are next to each other, and a parent
/// is always the last child of its own parent while its runs arrive.
private struct TreeBuilder {
    let source: String
    let softBreak: MarkdownSoftBreak
    private var sourceLines: [Substring]?
    /// 0-based end line of the last run that had a source position.
    private var lastLine = -1
    private var nextHTMLIdentity = -1

    init(source: String, softBreak: MarkdownSoftBreak) {
        self.source = source
        self.softBreak = softBreak
    }

    mutating func build(from attributed: AttributedString) -> IntentNode {
        let root = IntentNode(identity: 0, kind: nil, line: 0)
        // One step per leaf block (same presentation intent), not per inline run. This is much faster.
        for (intent, range) in attributed.runs[\.presentationIntent] {
            let source = attributed[range]
            let scan = LeafScan(source)
            let hasImage = scan.hasImage
            let hasNonImageText = scan.hasNonImageText
            let firstLine = scan.firstLine
            let endLine = scan.endLine
            var line = firstLine

            // Foundation turns a soft break into " " but marks it with the `softBreak` intent.
            let convertsSoftBreaks = scan.hasSoftBreak && softBreak == .lineBreak
            var slice: AttributedString
            if scan.tags.contains(where: \.isMatched) {
                slice = Self.rewrite(source, tags: scan.tags, convertsSoftBreaks: convertsSoftBreaks)
            } else {
                slice = AttributedString(source)
                // Common case (soft breaks, no style tags): an in-place swap is about 6x faster than a rewrite.
                if convertsSoftBreaks { Self.convertSoftBreaks(in: &slice) }
            }
            slice.presentationIntent = nil
            slice.markdownSourcePosition = nil
            // Changed for the comparison: OS 26 Foundation adds this invisible attribute. cmark does not. Nothing reads it.
            if #available(iOS 26, *) { slice.listItemDelimiter = nil }

            guard let intent else {
                // Top-level HTML blocks have no presentation intent.
                appendHTMLBlocks(source, to: root)
                continue
            }

            let path = intent.components.reversed()
            if line == nil, case .thematicBreak = intent.components.first?.kind {
                // Foundation gives no source position for thematic breaks.
                line = findThematicBreakLine()
            }
            var current = root
            for component in path {
                if let last = current.children.last, last.identity == component.identity {
                    current = last
                } else {
                    let node = IntentNode(identity: component.identity, kind: component.kind, line: line)
                    current.children.append(node)
                    current = node
                }
                if current.line == nil { current.line = line }
            }
            switch intent.components.first?.kind {
            case .listItem, .blockQuote:
                // An HTML block inside a container has only the container intent (no paragraph).
                appendHTMLBlocks(source, to: current)
                continue
            default:
                break
            }
            current.text += slice
            current.hasImage = current.hasImage || hasImage
            current.hasNonImageText = current.hasNonImageText || hasNonImageText
            if let endLine {
                lastLine = endLine
                if case .header = intent.components.first?.kind, let firstLine, !isATXHeading(at: firstLine) {
                    // Foundation's position skips the `===` / `---` underline of a setext heading.
                    lastLine = endLine + 1
                }
            } else if let line {
                lastLine = line
            }
        }
        return root
    }

    /// Each HTML block is one run. Each becomes its own raw-text node, so no content is lost.
    private mutating func appendHTMLBlocks(_ source: AttributedSubstring, to parent: IntentNode) {
        for run in source.runs {
            var text = AttributedString(source[run.range])
            text.presentationIntent = nil
            text.markdownSourcePosition = nil
            if #available(iOS 26, *) { text.listItemDelimiter = nil }
            if String(text.characters).allSatisfy(\.isWhitespace) { continue }
            let position = run.markdownSourcePosition
            let node = IntentNode(identity: nextHTMLIdentity, kind: nil, line: position.map { $0.startLine - 1 } ?? lastLine + 1)
            nextHTMLIdentity -= 1
            node.text = text
            parent.children.append(node)
            if let position { lastLine = position.endLine - 1 }
        }
    }

    private mutating func lines() -> [Substring] {
        if let sourceLines { return sourceLines }
        // `\.isNewline` also splits "\r\n", which Swift treats as one Character.
        let split = source.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        sourceLines = split
        return split
    }

    private mutating func isATXHeading(at line: Int) -> Bool {
        let all = lines()
        guard line >= 0, line < all.count else { return true }
        return all[line].drop { $0 == " " || $0 == "\t" || $0 == ">" }.hasPrefix("#")
    }

    /// Copies the runs of one leaf block. Soft breaks become "\n". Matched style tags are removed
    /// and the text between them gets the style. Unmatched tags stay as literal text.
    private static func rewrite(
        _ source: AttributedSubstring,
        tags: [StyleTag],
        convertsSoftBreaks: Bool
    ) -> AttributedString {
        var result = AttributedString()
        var depth: [StyleTag.Style: Int] = [:]
        var tagIndex = 0
        for (index, run) in source.runs.enumerated() {
            if tagIndex < tags.count, tags[tagIndex].run == index {
                // This run holds only style tags. Drop matched ones, keep the rest as text.
                while tagIndex < tags.count, tags[tagIndex].run == index {
                    let tag = tags[tagIndex]
                    tagIndex += 1
                    if tag.isMatched {
                        depth[tag.style, default: 0] += tag.isClosing ? -1 : 1
                    } else {
                        result += styled(AttributedString(tag.text, attributes: run.attributes), depth: depth)
                    }
                }
                continue
            }
            let piece: AttributedString
            if convertsSoftBreaks, run.inlinePresentationIntent?.contains(.softBreak) == true {
                piece = AttributedString("\n", attributes: run.attributes)
            } else {
                piece = AttributedString(source[run.range])
            }
            result += styled(piece, depth: depth)
        }
        return result
    }

    /// Replaces each soft-break run (" ") with "\n" in place. Both are one character, so the
    /// ranges stay valid, and the run keeps its attributes, including the `.softBreak` marker.
    private static func convertSoftBreaks(in slice: inout AttributedString) {
        let ranges = slice.runs
            .filter { $0.inlinePresentationIntent?.contains(.softBreak) == true }
            .map(\.range)
        for range in ranges.reversed() {
            slice.characters.replaceSubrange(range, with: "\n")
        }
    }

    /// Adds the styles of the open tags to one piece (one run, so its attributes are uniform).
    private static func styled(_ piece: AttributedString, depth: [StyleTag.Style: Int]) -> AttributedString {
        var piece = piece
        var intent = piece.runs.first?.inlinePresentationIntent ?? []
        for (style, count) in depth where count > 0 {
            switch style {
            case .bold: intent.insert(.stronglyEmphasized)
            case .italic: intent.insert(.emphasized)
            case .strikethrough: intent.insert(.strikethrough)
            case .code: intent.insert(.code)
            case .underline:
                // SwiftUI's key, because `Text(AttributedString)` only reads SwiftUI/Foundation attributes.
                piece[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] = .single
            }
        }
        if !intent.isEmpty { piece.inlinePresentationIntent = intent }
        return piece
    }

    /// Finds the first line after `lastLine` that looks like `---`, `***` or `___`.
    private mutating func findThematicBreakLine() -> Int {
        let allLines = lines()
        var index = max(lastLine + 1, 0)
        while index < allLines.count {
            let marks = allLines[index].filter { $0 != " " && $0 != "\t" && $0 != ">" && $0 != "\r" }
            if marks.count >= 3, let first = marks.first, "-*_".contains(first), marks.allSatisfy({ $0 == first }) {
                return index
            }
            index += 1
        }
        return lastLine + 1
    }
}

// MARK: - Step 2: intent tree -> model

private struct BlockConverter {
    private var nextID = 0

    mutating func blocks(from nodes: [IntentNode]) -> [MarkdownBlock] {
        nodes.compactMap { block(from: $0) }
    }

    private mutating func makeID() -> Int {
        defer { nextID += 1 }
        return nextID
    }

    private mutating func block(from node: IntentNode) -> MarkdownBlock? {
        let id = makeID()
        let line = node.line ?? 0
        guard let kind = node.kind else {
            return MarkdownBlock(id: id, sourceLine: line, kind: .paragraph(node.text))
        }
        switch kind {
        case .header(let level):
            return MarkdownBlock(id: id, sourceLine: line, kind: .heading(level: level, text: node.text))
        case .paragraph:
            if node.hasImage && !node.hasNonImageText {
                let url = node.text.runs.first?.imageURL
                return MarkdownBlock(id: id, sourceLine: line, kind: .image(url: url, altText: String(node.text.characters)))
            }
            return MarkdownBlock(id: id, sourceLine: line, kind: .paragraph(node.text))
        case .codeBlock(let languageHint):
            var code = String(node.text.characters)
            while code.hasSuffix("\n") { code.removeLast() }
            let language = (languageHint?.isEmpty ?? true) ? nil : languageHint
            return MarkdownBlock(id: id, sourceLine: line, kind: .codeBlock(language: language, code: code))
        case .thematicBreak:
            return MarkdownBlock(id: id, sourceLine: line, kind: .thematicBreak)
        case .blockQuote:
            return MarkdownBlock(id: id, sourceLine: line, kind: .blockQuote(blocks(from: node.children)))
        case .orderedList, .unorderedList:
            return MarkdownBlock(id: id, sourceLine: line, kind: .list(list(from: node, isOrdered: kind == .orderedList)))
        case .table(let columns):
            return MarkdownBlock(id: id, sourceLine: line, kind: .table(table(from: node, columns: columns)))
        default:
            // Unknown container: keep its children, or its text when it has none.
            if node.children.isEmpty {
                return MarkdownBlock(id: id, sourceLine: line, kind: .paragraph(node.text))
            }
            return MarkdownBlock(id: id, sourceLine: line, kind: .blockQuote(blocks(from: node.children)))
        }
    }

    private mutating func list(from node: IntentNode, isOrdered: Bool) -> MarkdownList {
        var startIndex = 1
        if isOrdered, case .listItem(let ordinal) = node.children.first?.kind {
            startIndex = ordinal
        }
        let items = node.children.map { itemNode in
            var itemBlocks = blocks(from: itemNode.children)
            let checkbox = Self.removeTaskMarker(from: &itemBlocks)
            return MarkdownListItem(checkbox: checkbox, blocks: itemBlocks)
        }
        return MarkdownList(isOrdered: isOrdered, startIndex: startIndex, items: items)
    }

    /// GFM task items. Foundation keeps `[ ]` / `[x]` as plain text, so we detect them here.
    private static func removeTaskMarker(from blocks: inout [MarkdownBlock]) -> MarkdownListItem.Checkbox? {
        guard let first = blocks.first, case .paragraph(var text) = first.kind else { return nil }
        let plain = String(text.characters)
        let checkbox: MarkdownListItem.Checkbox
        if plain.hasPrefix("[ ] ") || plain == "[ ]" {
            checkbox = .unchecked
        } else if plain.hasPrefix("[x] ") || plain.hasPrefix("[X] ") || plain == "[x]" || plain == "[X]" {
            checkbox = .checked
        } else {
            return nil
        }
        let markerLength = min(4, text.characters.count)
        let end = text.characters.index(text.startIndex, offsetBy: markerLength)
        text.removeSubrange(text.startIndex..<end)
        blocks[0].kind = .paragraph(text)
        return checkbox
    }

    private func table(from node: IntentNode, columns: [PresentationIntent.TableColumn]) -> MarkdownTable {
        let count = columns.count
        var header = Array(repeating: AttributedString(), count: count)
        var rows: [[AttributedString]] = []
        for rowNode in node.children {
            var cells = Array(repeating: AttributedString(), count: count)
            for cellNode in rowNode.children {
                if case .tableCell(let column) = cellNode.kind, column < count {
                    cells[column] = cellNode.text
                }
            }
            if case .tableHeaderRow = rowNode.kind {
                header = cells
            } else {
                rows.append(cells)
            }
        }
        let modelColumns = columns.map { MarkdownTable.Column(alignment: Self.alignment(from: $0.alignment)) }
        return MarkdownTable(columns: modelColumns, header: header, rows: rows)
    }

    private static func alignment(from alignment: PresentationIntent.TableColumn.Alignment) -> MarkdownTable.Alignment {
        switch alignment {
        case .left: .left
        case .center: .center
        case .right: .right
        @unknown default: .none
        }
    }
}
