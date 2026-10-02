import Foundation
import Testing

/// The copied spec files must come from the swift-cmark revision pinned in `Package.resolved`.
@Suite struct SpecCorpusRevisionTests {
    private struct Resolved: Decodable {
        struct Pin: Decodable {
            struct State: Decodable {
                var revision: String
            }
            var identity: String
            var state: State
        }
        var pins: [Pin]
    }

    @Test func copiedSpecMatchesPinnedRevision() throws {
        let packageResolved = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Package.resolved")
        let resolved = try JSONDecoder().decode(Resolved.self, from: Data(contentsOf: packageResolved))
        let pinned = try #require(resolved.pins.first { $0.identity == "swift-cmark" }).state.revision
        let url = try #require(Bundle.module.url(forResource: "REVISION", withExtension: nil, subdirectory: "Fixtures/cmark-spec"))
        let copied = try String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(copied == pinned, "swift-cmark pin changed. Run `bash scripts/refresh-cmark-spec.sh` and commit the new copy.")
    }
}
