import Foundation
import MEGAFoundation
import MEGAMarkdown

/// Everything rich mode needs before it shows a file, made off the main thread:
/// the editor, the estimate facts and the chrome of each row, and the preview rows of each raw block.
struct RichEditorLoad: Sendable {
    enum Outcome: Sendable {
        case loaded(RichEditorLoad)
        /// A block is longer than `maxBlockLength`. The file opens in source mode.
        case blockTooLong(units: Int)
    }

    /// In UTF-16 units. A text view lays out one paragraph as one unit, so each key in a longer block stalls.
    static let maxBlockLength = 100_000

    let editor: RichEditor
    let metrics: [RichRowMetrics]
    let chrome: RichChromeIndex
    /// The preview rows of each raw block. Empty for a block that shows nothing (definitions only, blank).
    let rawRows: [RichRowID: [PreviewRow]]
    /// The link reference definitions `rawRows` were rendered with.
    let definitions: String

    /// About 350 ms at the rich limit on an iPhone 15, so it never runs on the main thread.
    @concurrent
    static func load(_ markdown: String) async -> Outcome {
        make(markdown)
    }

    /// The synchronous load. Tests call it directly.
    static func make(_ markdown: String) -> Outcome {
        let editor = RichEditor(markdown: markdown)
        var metrics: [RichRowMetrics] = []
        metrics.reserveCapacity(editor.rows.count)
        var rawSources: [(RichRowID, String)] = []
        for row in editor.rows {
            // Raw blocks render split into preview rows, so only text views have the limit.
            if let units = row.block.plainText?.utf16.count, units > maxBlockLength {
                MEGALog.log(level: .info, message: "[RichEditorLoad] A block is too long for rich mode. units=\(units) limit=\(maxBlockLength)")
                return .blockTooLong(units: units)
            }
            metrics.append(RichRowMetrics(block: row.block))
            if case .rawSource(let source) = row.block { rawSources.append((row.id, source)) }
        }
        let definitions = rawSources.isEmpty ? "" : editor.referenceDefinitionSource
        var rawRows: [RichRowID: [PreviewRow]] = [:]
        for (id, source) in rawSources {
            rawRows[id] = PreviewRows.rows(forMarkdown: source, softBreak: .lineBreak, definitions: definitions)
        }
        let chrome = RichChromeIndex(blocks: editor.rows.lazy.map(\.block), numbers: editor.orderedNumbers())
        return .loaded(RichEditorLoad(editor: editor, metrics: metrics, chrome: chrome, rawRows: rawRows, definitions: definitions))
    }
}
