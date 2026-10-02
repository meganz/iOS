import Foundation

/// Reads the cmark spec files in `Fixtures/cmark-spec` the same way as cmark's `spec_tests.py`.
/// An example is the Markdown between a `` ```...``` example `` line and a `.` line. `→` means a tab.
enum SpecCorpus {
    struct Example {
        var file: String
        var number: Int
        var section: String
        var markdown: String
        var html: String
    }

    static let fileNames = ["spec", "extensions", "regression", "smart_punct"]

    static let examples: [Example] = fileNames.flatMap { name in
        guard let url = Bundle.module.url(forResource: name, withExtension: "txt", subdirectory: "Fixtures/cmark-spec"),
              let data = try? Data(contentsOf: url) else { return [Example]() }
        return parse(data, file: name)
    }

    /// Lines end at `\n` only, so a `\r` inside an example stays in the Markdown (regression.txt needs it).
    static func parse(_ data: Data, file: String) -> [Example] {
        let fence = String(repeating: "`", count: 32)
        var examples: [Example] = []
        var state = 0 // 0 prose, 1 markdown, 2 html
        var markdown = ""
        var html = ""
        var section = ""
        var number = 0
        var disabled = false
        for lineBytes in data.split(separator: 0x0A, omittingEmptySubsequences: false) {
            let line = String(decoding: lineBytes, as: UTF8.self) + "\n"
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix(fence + " example") {
                state = 1
                disabled = trimmed.contains("disabled")
            } else if trimmed == fence {
                state = 0
                number += 1
                if !disabled {
                    examples.append(Example(
                        file: file, number: number, section: section,
                        markdown: markdown.replacingOccurrences(of: "→", with: "\t"),
                        html: html.replacingOccurrences(of: "→", with: "\t")))
                }
                markdown = ""
                html = ""
            } else if trimmed == "." {
                state = 2
            } else if state == 1 {
                markdown += line
            } else if state == 2 {
                html += line
            } else if line.hasPrefix("#"), let title = line.split(separator: " ", maxSplits: 1).last {
                section = title.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return examples
    }
}
