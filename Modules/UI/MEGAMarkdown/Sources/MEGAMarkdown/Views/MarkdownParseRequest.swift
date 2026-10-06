import Foundation

/// Everything the parser needs. A change in any field means a new parse.
struct MarkdownParseRequest: Equatable, Sendable {
    var markdown: String
    var baseURL: URL?
    var softBreak: MarkdownSoftBreak = .lineBreak

    func parse() -> MarkdownDocument {
        MarkdownParser.parse(markdown, baseURL: baseURL, softBreak: softBreak)
    }

    /// Compares the text by bytes. String `==` treats "é" and "e" + U+0301 as equal, but cmark matches
    /// reference labels by bytes, so the two can parse differently.
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.baseURL == rhs.baseURL && lhs.softBreak == rhs.softBreak && sameBytes(lhs.markdown, rhs.markdown)
    }

    private static func sameBytes(_ lhs: String, _ rhs: String) -> Bool {
        guard lhs.utf8.count == rhs.utf8.count else { return false }
        let fast = lhs.utf8.withContiguousStorageIfAvailable { left in
            rhs.utf8.withContiguousStorageIfAvailable { right in
                guard let leftBase = left.baseAddress, let rightBase = right.baseAddress, leftBase != rightBase else { return true }
                return memcmp(leftBase, rightBase, left.count) == 0
            }
        }
        return fast.flatMap { $0 } ?? lhs.utf8.elementsEqual(rhs.utf8)
    }
}

/// A document parse result and the request it came from (used by `MarkdownView`).
struct ParsedMarkdown: Equatable {
    let source: MarkdownParseRequest
    let document: MarkdownDocument
}
