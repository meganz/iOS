import MEGAMarkdown

extension RichDocument {
    /// The link reference definitions of the raw blocks, joined with blank lines.
    /// A view that renders one raw block alone puts this in front, so `[text][label]` resolves like in the whole file.
    var referenceDefinitionSource: String {
        Self.referenceDefinitionSource(of: blocks)
    }

    /// `referenceDefinitionSource` without building a document. The editor calls it with its rows.
    /// Converted blocks never hold a definition: the importer keeps such a block raw.
    static func referenceDefinitionSource(of blocks: some Sequence<RichBlock>) -> String {
        blocks.flatMap { block -> [String] in
            guard case .rawSource(let source) = block else { return [] }
            return definitionRuns(in: source)
        }
        .joined(separator: "\n\n")
    }

    /// Runs of lines outside every parsed block that start with `[`: definitions render nothing, so they hold no block.
    /// Lines inside a code fence or a table belong to a block, so they never count.
    private static func definitionRuns(in source: String) -> [String] {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        // Most raw blocks have no line that can start a definition, and then need no parse.
        guard lines.contains(where: startsDefinition), let parsed = CmarkParser.editorBlocks(source) else { return [] }
        var covered = [Bool](repeating: false, count: lines.count)
        for range in parsed.lines {
            for line in range where line < lines.count { covered[line] = true }
        }
        var runs: [String] = []
        var run: [Substring] = []
        for (index, line) in lines.enumerated() {
            let isFree = !covered[index] && !line.allSatisfy { $0 == " " || $0 == "\t" }
            if isFree && (!run.isEmpty || startsDefinition(line)) {
                run.append(line)
            } else if !run.isEmpty {
                runs.append(run.joined(separator: "\n"))
                run = []
            }
        }
        if !run.isEmpty { runs.append(run.joined(separator: "\n")) }
        return runs
    }

    /// `[` after at most 3 spaces.
    private static func startsDefinition(_ line: Substring) -> Bool {
        let indent = line.prefix { $0 == " " }.count
        return indent <= 3 && line.dropFirst(indent).first == "["
    }
}

extension RichEditor {
    /// `RichDocument.referenceDefinitionSource` of the rows. O(rows) plus one small parse per definition block.
    var referenceDefinitionSource: String {
        RichDocument.referenceDefinitionSource(of: rows.lazy.map(\.block))
    }
}
