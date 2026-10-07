import Foundation
import Testing

/// The cmark spec examples, read from the parser tests' fixtures (`Tests/MEGAMarkdownTests/Fixtures/cmark-spec`).
/// An example is the Markdown between a `` ```...``` example `` line and a `.` line. `→` means a tab.
enum SpecExamples {
    struct Example: CustomStringConvertible, CustomTestStringConvertible, Sendable {
        var file: String
        var number: Int
        var markdown: String

        var description: String { "\(file) #\(number)" }
        var testDescription: String { description }
    }

    static let fileNames = ["spec", "extensions", "regression"]

    /// Examples the spec files mark as disabled. They are not in `all`.
    static let disabledCount = parsed.reduce(0) { $0 + $1.disabled }

    static let all: [Example] = parsed.flatMap(\.examples)

    private static let parsed: [(examples: [Example], disabled: Int)] = fileNames.map { name in
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("MEGAMarkdownTests/Fixtures/cmark-spec/\(name).txt")
        guard let data = try? Data(contentsOf: url) else { return ([], 0) }
        return parse(data, file: name)
    }

    private static func parse(_ data: Data, file: String) -> (examples: [Example], disabled: Int) {
        let fence = String(repeating: "`", count: 32)
        var examples: [Example] = []
        var state = 0 // 0 prose, 1 markdown, 2 html
        var markdown = ""
        var number = 0
        var disabled = false
        var disabledCount = 0
        for lineBytes in data.split(separator: 0x0A, omittingEmptySubsequences: false) {
            let line = String(decoding: lineBytes, as: UTF8.self) + "\n"
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix(fence + " example") {
                state = 1
                disabled = trimmed.contains("disabled")
            } else if trimmed == fence {
                state = 0
                number += 1
                if disabled {
                    disabledCount += 1
                } else {
                    examples.append(Example(file: file, number: number, markdown: markdown.replacingOccurrences(of: "→", with: "\t")))
                }
                markdown = ""
            } else if trimmed == ".", state == 1 {
                state = 2
            } else if state == 1 {
                markdown += line
            }
        }
        return (examples, disabledCount)
    }
}
