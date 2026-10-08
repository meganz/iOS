import Foundation

/// The facts a height estimate needs for one rich row, without building text.
/// Counting code lines reads the whole code, so the load makes these off the main thread,
/// and an edit makes them again only for the rows it replaced.
enum RichRowMetrics: Equatable, Sendable {
    /// Paragraph, heading, list item or quote. UTF-8 bytes, like the preview's estimate.
    case text(bytes: Int, headingLevel: Int?)
    case code(lines: Int, hasLanguage: Bool)
    case divider
    /// A raw block. Its preview rows give the estimate.
    case raw

    init(block: RichBlock) {
        switch block {
        case .paragraph(let text), .listItem(_, let text), .quote(_, let text):
            self = .text(bytes: text.text.utf8.count, headingLevel: nil)
        case .heading(let level, let text):
            self = .text(bytes: text.text.utf8.count, headingLevel: level)
        case .codeBlock(let language, let code):
            let lines = code.utf8.reduce(1) { $0 + ($1 == 10 ? 1 : 0) }
            self = .code(lines: lines, hasLanguage: !(language ?? "").isEmpty)
        case .thematicBreak:
            self = .divider
        case .rawSource:
            self = .raw
        }
    }
}
