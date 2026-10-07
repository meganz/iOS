import Foundation

/// Markdown made of sections that differ in text, kind and size, so no two rows have the same content or height.
/// The same seed gives the same text on every run. This is a Swift port of `varied_sections` in
/// `DemoApp/scripts/make_test_files.py`. The random numbers differ, so the text differs from the demo files.
enum VariedSections {
    static let seed: UInt64 = 12683

    /// The text for `megabytes` MiB. A copy is kept in the caches folder, because a 50 MB file takes seconds to make.
    @concurrent
    static func cachedText(megabytes: Int) async -> String {
        let url = URL.cachesDirectory.appending(path: "varied-sections-\(seed)-\(megabytes)mb.md")
        if let data = try? Data(contentsOf: url) {
            return String(decoding: data, as: UTF8.self)
        }
        let text = make(targetBytes: megabytes * 1024 * 1024)
        try? Data(text.utf8).write(to: url)
        return text
    }

    static func make(targetBytes: Int) -> String {
        var generator = Generator(seed: seed)
        var parts: [String] = []
        var size = 0
        var number = 0
        while size < targetBytes {
            number += 1
            var blocks = ["\(String(repeating: "#", count: generator.int(1, 4))) \(number). \(generator.words(2, 10))"]
            for _ in 0..<generator.int(1, 6) {
                blocks.append(generator.block())
            }
            if generator.double() < 0.15 {
                blocks.append("---")
            }
            let part = blocks.joined(separator: "\n\n") + "\n\n"
            parts.append(part)
            size += part.utf8.count
        }
        return parts.joined()
    }
}

private struct Generator {
    private static let vocabulary = (
        "cloud drive folder file share link backup sync photo video album upload download transfer quota storage "
        + "account device contact chat meeting note text table code block list item quote heading paragraph line "
        + "secure private encrypted fast simple large small quick slow first last next other every each some many "
        + "open close move copy rename delete restore save keep show hide read write check select scroll tap"
    ).split(separator: " ").map(String.init)

    // SplitMix64: a small generator with a fixed output for a given seed.
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    private mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    mutating func double() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }

    /// A number from `low` to `high`, both included.
    mutating func int(_ low: Int, _ high: Int) -> Int {
        low + Int(next() % UInt64(high - low + 1))
    }

    private mutating func word() -> String {
        Self.vocabulary[int(0, Self.vocabulary.count - 1)]
    }

    mutating func words(_ low: Int, _ high: Int) -> String {
        (0..<int(low, high)).map { _ in word() }.joined(separator: " ")
    }

    mutating func block() -> String {
        switch int(0, 6) {
        case 0, 1, 2: paragraph()
        case 3: bulletList()
        case 4: quote()
        case 5: code()
        default: table()
        }
    }

    private mutating func sentence() -> String {
        var text = words(3, 18)
        let style = double()
        if style < 0.15 {
            if let space = text.firstIndex(of: " ") {
                text.replaceSubrange(space...space, with: " **")
            }
            text += "**"
        } else if style < 0.25 {
            text += " `\(word())()`"
        } else if style < 0.32 {
            text += " [\(word())](https://mega.io/\(word()))"
        }
        return text.prefix(1).uppercased() + text.dropFirst() + "."
    }

    private mutating func sentences(_ low: Int, _ high: Int) -> String {
        (0..<int(low, high)).map { _ in sentence() }.joined(separator: " ")
    }

    private mutating func paragraph() -> String {
        sentences(1, 14)
    }

    private mutating func bulletList() -> String {
        var lines: [String] = []
        let isTask = double() < 0.3
        let isOrdered = !isTask && double() < 0.4
        for index in 0..<int(1, 12) {
            let marker: String
            if isOrdered {
                marker = "\(index + 1)."
            } else if isTask {
                marker = double() < 0.5 ? "- [x]" : "- [ ]"
            } else {
                marker = "-"
            }
            lines.append("\(marker) \(sentences(1, 4))")
            if !isOrdered && double() < 0.2 {
                lines.append("  - \(sentence())")
            }
        }
        return lines.joined(separator: "\n")
    }

    private mutating func quote() -> String {
        (0..<int(1, 3)).map { _ in "> " + paragraph() }.joined(separator: "\n>\n")
    }

    private mutating func code() -> String {
        let lines = (0..<int(1, 40)).map { index in
            let longest = [3, 12, 30][int(0, 2)]
            return "let \(word())\(index) = \"\(words(1, longest))\""
        }
        return "```swift\n" + lines.joined(separator: "\n") + "\n```"
    }

    private mutating func table() -> String {
        let columns = int(2, 6)
        let rows = (0..<int(1, 15)).map { _ in
            (0..<columns).map { _ in words(1, 6) }.joined(separator: " | ")
        }
        let header = (0..<columns).map { _ in words(1, 2) }.joined(separator: " | ")
        let separator = "|" + String(repeating: "---|", count: columns)
        return (["| \(header) |", separator] + rows.map { "| \($0) |" }).joined(separator: "\n")
    }
}
