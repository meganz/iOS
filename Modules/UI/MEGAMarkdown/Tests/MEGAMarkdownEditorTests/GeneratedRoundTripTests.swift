import Foundation
@testable import MEGAMarkdownEditor
import Testing

/// Random documents of rich blocks: export, then import, gives the same blocks.
/// It tests the exporter on content that did not come from Markdown, as after edits.
@Suite("Round trip of generated documents")
struct GeneratedRoundTripTests {
    /// To replay one failing seed, set this to `[seed]` while you debug. Do not commit that change.
    /// For a deeper check, widen the range for one local run.
    static let seeds: [UInt64] = Array(0..<400)

    @Test func generatedDocumentsComeBackTheSame() {
        var failures: [String] = []
        for seed in Self.seeds {
            var generator = RichDocumentGenerator(seed: seed)
            let blocks = generator.document(blockCount: 8)
            let markdown = exportedBody(blocks)
            let loaded = RichMarkdownConverter.load(markdown)
            let expected = blocks.filter { !Self.isEmptyParagraph($0) }
            let actual = loaded.document.blocks.filter { !Self.isEmptyParagraph($0) }
            if actual != expected || loaded.rawBlockCount > 0 {
                failures.append(Self.describe(seed: seed, markdown: markdown, expected: expected, actual: actual))
            }
        }
        #expect(failures.isEmpty, "\(failures.count) of \(Self.seeds.count):\n\(failures.prefix(5).joined(separator: "\n\n"))")
    }

    private static func isEmptyParagraph(_ block: RichBlock) -> Bool {
        if case .paragraph(let text) = block { return text.isEmpty }
        return false
    }

    private static func describe(seed: UInt64, markdown: String, expected: [RichBlock], actual: [RichBlock]) -> String {
        let firstDifference = (0..<min(expected.count, actual.count)).first { expected[$0] != actual[$0] }
        var lines = ["seed \(seed)", "--- markdown", markdown, "---"]
        // The first block that does not come back alone is usually the cause.
        let alone = expected.first { block in
            (block.listItem?.indent ?? 0) == 0 && loadedBlocks(exportedBody([block])).filter { !isEmptyParagraph($0) } != [block]
        }
        if let alone {
            lines.append("alone: \(alone)\n  writes \(exportedBody([alone]).debugDescription)\n  loads  \(loadedBlocks(exportedBody([alone])))")
        } else if let pair = expected.indices.dropLast().first(where: { index in
            let pair = Array(expected[index...(index + 1)])
            return (pair[0].listItem?.indent ?? 0) == 0 && loadedBlocks(exportedBody(pair)).filter { !isEmptyParagraph($0) } != pair.filter { !isEmptyParagraph($0) }
        }) {
            let blocks = Array(expected[pair...(pair + 1)])
            lines.append("pair: \(blocks)\n  writes \(exportedBody(blocks).debugDescription)\n  loads  \(loadedBlocks(exportedBody(blocks)))")
        }
        if let firstDifference {
            lines.append("block \(firstDifference):\n  expected \(expected[firstDifference])\n  actual   \(actual[firstDifference])")
        } else {
            lines.append("count expected \(expected.count), actual \(actual.count)")
            lines.append("  actual \(actual)")
        }
        return lines.joined(separator: "\n")
    }
}
