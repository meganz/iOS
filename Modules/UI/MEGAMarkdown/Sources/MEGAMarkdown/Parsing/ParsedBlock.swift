import Foundation

/// Internal parse result. Same shape as `MarkdownBlock`, but text is kept as cheap `InlineText`.
/// `MarkdownParser.parse` converts all of it. The preview converts only the rows on screen.
package struct ParsedBlock: Equatable, Sendable {
    /// 0-based line in the source text where this block starts.
    package var sourceLine: Int
    package var kind: Kind

    // Not `indirect`: the arrays already break the recursion, and a box per block costs memory.
    package enum Kind: Equatable, Sendable {
        case heading(level: Int, text: InlineText)
        /// Also HTML blocks: their text has the `.blockHTML` style, like Foundation.
        case paragraph(InlineText)
        case list(ParsedList)
        /// Same rules as `MarkdownBlock.Kind.codeBlock`: no trailing newline, and `\n` line ends.
        case codeBlock(language: String?, code: String)
        case blockQuote([ParsedBlock])
        case table(ParsedTable)
        case thematicBreak
        /// A paragraph that holds only images. `url` is the first image's URL as written.
        case image(url: String?, altText: String)
    }
}

package struct ParsedList: Equatable, Sendable {
    package var isOrdered: Bool
    package var startIndex: Int
    package var items: [ParsedListItem]
}

package struct ParsedListItem: Equatable, Sendable {
    package var checkbox: MarkdownListItem.Checkbox?
    package var blocks: [ParsedBlock]
}

package struct ParsedTable: Equatable, Sendable {
    package var columns: [MarkdownTable.Column]
    package var header: [InlineText]
    package var rows: [[InlineText]]
    /// 0-based source line of each row in `rows`. Dropped empty rows leave gaps, so an index is not a line.
    package var rowLines: [Int]
}

// MARK: - Conversion to the public model

extension ParsedBlock {
    /// Ids are given depth first, parent before children, like Foundation's `AttributedString(markdown:)`.
    func markdownBlock(nextID: inout Int, baseURL: URL?) -> MarkdownBlock {
        let id = nextID
        nextID += 1
        let modelKind: MarkdownBlock.Kind
        switch kind {
        case .heading(let level, let text):
            modelKind = .heading(level: level, text: text.attributed(baseURL: baseURL))
        case .paragraph(let text):
            modelKind = .paragraph(text.attributed(baseURL: baseURL))
        case .list(let list):
            let items = list.items.map { item in
                MarkdownListItem(checkbox: item.checkbox, blocks: item.blocks.map { $0.markdownBlock(nextID: &nextID, baseURL: baseURL) })
            }
            modelKind = .list(MarkdownList(isOrdered: list.isOrdered, startIndex: list.startIndex, items: items))
        case .codeBlock(let language, let code):
            modelKind = .codeBlock(language: language, code: code)
        case .blockQuote(let children):
            modelKind = .blockQuote(children.map { $0.markdownBlock(nextID: &nextID, baseURL: baseURL) })
        case .table(let table):
            modelKind = .table(MarkdownTable(
                columns: table.columns,
                header: table.header.map { $0.attributed(baseURL: baseURL) },
                rows: table.rows.map { row in row.map { $0.attributed(baseURL: baseURL) } }
            ))
        case .thematicBreak:
            modelKind = .thematicBreak
        case .image(let url, let altText):
            modelKind = .image(url: url.flatMap { InlineLink.makeURL($0, relativeTo: baseURL) }, altText: altText)
        }
        return MarkdownBlock(id: id, sourceLine: sourceLine, kind: modelKind)
    }
}
