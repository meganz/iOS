import Foundation
@testable import MEGAMarkdown
import Testing

/// Every Markdown file in `Fixtures/parity` has a golden file in `Fixtures/golden` with the exact parser output.
/// The goldens were written while the old Foundation parity test still passed, so they carry that proof.
/// After a wanted output change, write them again with
/// `export TEST_RUNNER_MARKDOWN_WRITE_GOLDENS=<absolute path of Fixtures/golden>`. Write mode fails on purpose.
@Suite struct ParserGoldenTests {
    static let fixtureNames: [String] = {
        guard let folder = Bundle.module.url(forResource: "parity", withExtension: nil, subdirectory: "Fixtures"),
              let names = try? FileManager.default.contentsOfDirectory(atPath: folder.path) else { return [] }
        return names.filter { $0.hasSuffix(".md") }.sorted()
    }()

    static func fixture(_ name: String) throws -> String {
        let url = try #require(Bundle.module.url(forResource: "parity/\(name)", withExtension: nil, subdirectory: "Fixtures"))
        return try String(contentsOf: url, encoding: .utf8)
    }

    @Test func fixturesExist() {
        // Every file in the folder, so a lost fixture fails here.
        #expect(Self.fixtureNames.count == 65)
    }

    @Test(arguments: fixtureNames)
    func outputMatchesGolden(name: String) throws {
        let markdown = try Self.fixture(name)
        let dump = MarkdownDocumentDump.dump(MarkdownParser.parse(markdown))
        let goldenName = String(name.dropLast(3))
        if let folder = ProcessInfo.processInfo.environment["MARKDOWN_WRITE_GOLDENS"] {
            try dump.write(to: URL(fileURLWithPath: folder).appending(path: "\(goldenName).txt"), atomically: true, encoding: .utf8)
            Issue.record("Wrote \(goldenName).txt. Run again without MARKDOWN_WRITE_GOLDENS.")
            return
        }
        let url = try #require(Bundle.module.url(forResource: "golden/\(goldenName)", withExtension: "txt", subdirectory: "Fixtures"))
        let golden = try String(contentsOf: url, encoding: .utf8)
        #expect(Self.firstDifferentLine(golden, dump) == nil)
    }

    /// The first line that differs, so a failure shows one line and not two long strings.
    static func firstDifferentLine(_ expected: String, _ actual: String) -> String? {
        let left = expected.split(separator: "\n", omittingEmptySubsequences: false)
        let right = actual.split(separator: "\n", omittingEmptySubsequences: false)
        for (index, pair) in zip(left, right).enumerated() where pair.0 != pair.1 {
            return "line \(index + 1):\n  golden \(pair.0)\n  actual \(pair.1)"
        }
        if left.count != right.count { return "line count: golden \(left.count), actual \(right.count)" }
        return nil
    }
}
