import Foundation
@testable import MEGAMarkdown
import Testing

/// The chunk rule over every CommonMark and GFM spec example: a chunked parse must give the same tree as one whole parse.
/// The examples come from cmark itself (`Fixtures/cmark-spec`), so the inputs do not depend on what a reviewer imagined.
@Suite struct SpecCorpusChunkTests {
    @Test func examplesExist() {
        let counts = Dictionary(grouping: SpecCorpus.examples, by: \.file).mapValues(\.count)
        // spec.txt has 672 examples, 2 of them disabled.
        #expect(counts == ["spec": 670, "extensions": 30, "regression": 26, "smart_punct": 16])
    }

    @Test func tabsAndCarriageReturnsAreKept() throws {
        let tab = try #require(SpecCorpus.examples.first { $0.file == "spec" && $0.number == 1 })
        #expect(tab.markdown == "\tfoo\tbaz\t\tbim\n")
        #expect(SpecCorpus.examples.contains { $0.file == "regression" && $0.markdown.contains("\r") })
    }

    /// Every example on its own, cut at small targets so the cut lands inside each construct.
    @Test(arguments: [1, 2, 5, 13, 50])
    func everyExampleMatchesWholeParse(target: Int) {
        var mismatches: [String] = []
        for example in SpecCorpus.examples {
            let whole = ChunkedParseTests.whole(example.markdown)
            let chunked = ChunkedParseTests.chunked(example.markdown, target: target).trees
            if let difference = ChunkedParseTests.firstDifference(whole, chunked) {
                mismatches.append("\(example.file) #\(example.number) (\(example.section)) \(example.markdown.debugDescription)\n\(difference)")
            }
        }
        #expect(mismatches.isEmpty, "\(mismatches.count) mismatches\n\(mismatches.prefix(5).joined(separator: "\n"))")
    }

    /// Random examples joined into one text, like the snippet fuzz in `ChunkedParseTests` but with the spec pool.
    @Test(.timeLimit(.minutes(10)))
    func joinedExamplesMatchWholeParse() {
        let iterations = ProcessInfo.processInfo.environment["MARKDOWN_FUZZ_ITERATIONS"].flatMap(Int.init) ?? 400
        var generator = ChunkedParseTests.Seeded(state: 7)
        var cases = 0
        var mismatches: [String] = []
        for _ in 0..<iterations {
            let count = Int.random(in: 2...8, using: &generator)
            let parts = (0..<count).map { _ in SpecCorpus.examples.randomElement(using: &generator)?.markdown ?? "" }
            let separator = ["", "\n", "\n\n"].randomElement(using: &generator) ?? "\n"
            let text = parts.joined(separator: separator)
            let whole = ChunkedParseTests.whole(text)
            let targets = [1, Int.random(in: 2...40, using: &generator), Int.random(in: 40...400, using: &generator)]
            for target in targets {
                cases += 1
                if let difference = ChunkedParseTests.firstDifference(whole, ChunkedParseTests.chunked(text, target: target).trees) {
                    mismatches.append("target \(target) \(text.debugDescription)\n\(difference)")
                }
            }
        }
        print("spec fuzz: iterations=\(iterations) cases=\(cases) mismatches=\(mismatches.count)")
        #expect(mismatches.isEmpty, "\(mismatches.count) mismatches\n\(mismatches.prefix(3).joined(separator: "\n"))")
    }
}
