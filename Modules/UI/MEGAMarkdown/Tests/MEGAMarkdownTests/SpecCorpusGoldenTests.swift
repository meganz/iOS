import Foundation
@testable import MEGAMarkdown
import Testing

/// The parser output for every cmark spec example, frozen in one golden file.
/// It does not prove the output is right. It shows exactly which spec examples a change touches.
/// After a wanted output change, write it again with
/// `export TEST_RUNNER_MARKDOWN_WRITE_GOLDENS=<absolute path of Fixtures/golden>`. Write mode fails on purpose.
@Suite struct SpecCorpusGoldenTests {
    static let goldenName = "cmark-spec-examples"

    static func dumpAll() -> String {
        SpecCorpus.examples.map { example in
            "## \(example.file) \(example.number) \(example.section)\n" + MarkdownDocumentDump.dump(MarkdownParser.parse(example.markdown))
        }.joined(separator: "\n")
    }

    @Test func outputMatchesGolden() throws {
        let dump = Self.dumpAll()
        if let folder = ProcessInfo.processInfo.environment["MARKDOWN_WRITE_GOLDENS"] {
            try dump.write(to: URL(fileURLWithPath: folder).appending(path: "\(Self.goldenName).txt"), atomically: true, encoding: .utf8)
            Issue.record("Wrote \(Self.goldenName).txt. Run again without MARKDOWN_WRITE_GOLDENS.")
            return
        }
        let url = try #require(Bundle.module.url(forResource: "golden/\(Self.goldenName)", withExtension: "txt", subdirectory: "Fixtures"))
        let golden = try String(contentsOf: url, encoding: .utf8)
        #expect(ParserGoldenTests.firstDifferentLine(golden, dump) == nil)
    }
}
