import Foundation
@testable import MEGAMarkdown

// Small helpers so tests can read the model tree without long `if case` chains.

func parse(_ markdown: String) -> [MarkdownBlock] {
    MarkdownParser.parse(markdown).blocks
}

extension AttributedString {
    var plain: String { String(characters) }
}

extension MarkdownBlock {
    var paragraph: AttributedString? {
        if case .paragraph(let text) = kind { return text }
        return nil
    }

    var paragraphText: String? {
        if case .paragraph(let text) = kind { return text.plain }
        return nil
    }

    var heading: (level: Int, text: String)? {
        if case .heading(let level, let text) = kind { return (level, text.plain) }
        return nil
    }

    var list: MarkdownList? {
        if case .list(let list) = kind { return list }
        return nil
    }

    var quote: [MarkdownBlock]? {
        if case .blockQuote(let blocks) = kind { return blocks }
        return nil
    }

    var code: (language: String?, code: String)? {
        if case .codeBlock(let language, let code) = kind { return (language, code) }
        return nil
    }

    var table: MarkdownTable? {
        if case .table(let table) = kind { return table }
        return nil
    }

    var image: (url: URL?, altText: String)? {
        if case .image(let url, let altText) = kind { return (url, altText) }
        return nil
    }

    var isThematicBreak: Bool {
        if case .thematicBreak = kind { return true }
        return false
    }

    /// Children of container blocks, for walking the whole tree.
    var childBlocks: [MarkdownBlock] {
        switch kind {
        case .blockQuote(let blocks): blocks
        case .list(let list): list.items.flatMap(\.blocks)
        default: []
        }
    }
}

/// All blocks in depth-first order (parent before children).
func flatten(_ blocks: [MarkdownBlock]) -> [MarkdownBlock] {
    blocks.flatMap { [$0] + flatten($0.childBlocks) }
}
