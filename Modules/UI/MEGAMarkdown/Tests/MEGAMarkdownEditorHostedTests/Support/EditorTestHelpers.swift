import Foundation
@testable import MEGAMarkdownEditor

// The helpers the hosted tests use. MEGAMarkdownEditorTests has its own copy, because a file belongs to one target.

func paragraph(_ text: String, _ spans: (Range<Int>, RichSpanStyle)...) -> RichBlock {
    .paragraph(RichText(text, spans: spans.map { RichSpan(range: $0.0, style: $0.1) }))
}

func bullet(_ text: String, indent: Int = 0) -> RichBlock {
    .listItem(RichListItem(isOrdered: false, indent: indent), text: RichText(text))
}

func task(_ text: String, checked: Bool = false, indent: Int = 0) -> RichBlock {
    .listItem(RichListItem(isOrdered: false, indent: indent, isChecked: checked), text: RichText(text))
}

func heading(_ level: Int, _ text: String) -> RichBlock {
    .heading(level: level, text: RichText(text))
}

func position(_ block: Int, _ offset: Int) -> RichPosition {
    RichPosition(blockIndex: block, offset: offset)
}
