import Foundation
import MEGAMarkdown
@testable import MEGAMarkdownEditor

/// Rich text with spans written as (range, style) pairs.
func rich(_ text: String, _ spans: (Range<Int>, RichSpanStyle)...) -> RichText {
    RichText(text, spans: spans.map { RichSpan(range: $0.0, style: $0.1) })
}

func paragraph(_ text: String, _ spans: (Range<Int>, RichSpanStyle)...) -> RichBlock {
    .paragraph(RichText(text, spans: spans.map { RichSpan(range: $0.0, style: $0.1) }))
}

func bullet(_ text: String, indent: Int = 0) -> RichBlock {
    .listItem(RichListItem(isOrdered: false, indent: indent), text: RichText(text))
}

func ordered(_ text: String, indent: Int = 0, start: Int? = nil) -> RichBlock {
    .listItem(RichListItem(isOrdered: true, indent: indent, startNumber: start), text: RichText(text))
}

func task(_ text: String, checked: Bool = false, indent: Int = 0) -> RichBlock {
    .listItem(RichListItem(isOrdered: false, indent: indent, isChecked: checked), text: RichText(text))
}

func heading(_ level: Int, _ text: String) -> RichBlock {
    .heading(level: level, text: RichText(text))
}

func quote(_ text: String, depth: Int = 1) -> RichBlock {
    .quote(depth: depth, text: RichText(text))
}

func link(_ destination: String, title: String = "") -> RichSpanStyle {
    .link(RichLink(destination: destination, title: title))
}

/// The body of a file: what the converter writes, without the last line end.
func exportedBody(_ blocks: [RichBlock]) -> String {
    RichMarkdownConverter.markdownFragment(from: blocks)
}

/// The blocks a Markdown text loads as.
func loadedBlocks(_ markdown: String) -> [RichBlock] {
    RichMarkdownConverter.document(from: markdown).blocks
}

/// True when two Markdown texts mean the same, by the editor parse of both.
func meansTheSame(_ lhs: String, _ rhs: String) -> Bool {
    guard let left = CmarkParser.editorBlocks(MarkdownSourceText(lhs).body)?.blocks,
          let right = CmarkParser.editorBlocks(MarkdownSourceText(rhs).body)?.blocks else { return false }
    return ParsedBlockEquivalence.isEquivalent(left, right)
}

/// An editor on blocks, with the caret at `caret`.
func editor(_ blocks: [RichBlock], caret: RichPosition = RichPosition(blockIndex: 0, offset: 0)) -> RichEditor {
    var editor = RichEditor(newFile: RichDocument(blocks: blocks))
    editor.select(.caret(caret))
    return editor
}

func position(_ block: Int, _ offset: Int) -> RichPosition {
    RichPosition(blockIndex: block, offset: offset)
}

func selection(_ start: RichPosition, _ end: RichPosition) -> RichSelection {
    RichSelection(start: start, end: end)
}

extension RichEditor {
    var blocks: [RichBlock] { rows.map(\.block) }
}

/// A seeded generator, so a failing random case can run again.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // SplitMix64.
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}
