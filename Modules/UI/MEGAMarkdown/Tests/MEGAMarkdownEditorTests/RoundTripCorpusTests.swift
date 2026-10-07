import Foundation
import MEGAMarkdown
@testable import MEGAMarkdownEditor
import Testing

/// Every cmark spec example loads, exports and parses back to the same meaning.
@Suite("Round trip of the cmark spec examples")
struct RoundTripCorpusTests {
    /// 728 examples in the three files. Two are marked disabled in the spec file.
    @Test func specExamplesAreThere() {
        #expect(SpecExamples.all.count == 726)
        #expect(SpecExamples.disabledCount == 2)
    }

    @Test(arguments: SpecExamples.all)
    func everyExampleWritesBackTheSameMeaning(example: SpecExamples.Example) {
        let loaded = RichMarkdownConverter.load(example.markdown)
        #expect(meansTheSame(example.markdown, loaded.exported), "--- input\n\(example.markdown)--- export\n\(loaded.exported)")
    }

    @Test(arguments: SpecExamples.all)
    func exportIsStableOnReload(example: SpecExamples.Example) {
        let first = RichMarkdownConverter.load(example.markdown).exported
        let second = RichMarkdownConverter.load(first).exported
        #expect(second.hasSameBytes(as: first), "--- first\n\(first)--- second\n\(second)")
    }

    /// Examples the model holds, but the exporter cannot write without a change. They stay raw.
    /// - spec #336 `&#9;foo`: a tab at a line start. The exporter drops spaces and tabs at line edges.
    static let knownRepairs: Set<String> = ["spec #336"]

    /// A conversion that needs a repair round means the exporter wrote a block the model holds in a way
    /// that parses differently. That is an exporter bug, not a model limit.
    @Test(arguments: SpecExamples.all.filter { !knownRepairs.contains($0.description) })
    func everyConvertedBlockWritesBackWithoutRepair(example: SpecExamples.Example) {
        let loaded = RichMarkdownConverter.load(example.markdown)
        #expect(loaded.repairRounds == 0, "\(example.markdown)--- export\n\(loaded.exported)")
    }
}
