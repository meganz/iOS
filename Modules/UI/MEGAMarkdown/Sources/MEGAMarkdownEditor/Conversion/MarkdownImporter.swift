import MEGAFoundation
import MEGAMarkdown

/// The result of loading a Markdown file.
struct RichImport: Sendable {
    let document: RichDocument
    /// The export of `document`. A later export that differs from it means the user changed something.
    let exported: String
    /// Inline pieces of that export, so the next export writes only changed blocks again.
    let cache: InlineExportCache
    let rawBlockCount: Int
    /// Rounds that made blocks raw because they did not write back the same. 0 when every conversion was right.
    var repairRounds = 0
}

/// Markdown -> `RichDocument`.
///
/// Each top-level block becomes rich rows when the model can hold it, or a raw block with its exact source lines.
/// Lines that hold no block (link reference definitions) become raw blocks too, so no byte is lost.
/// Then the import checks itself: it exports the rows, parses the export, and compares it with the parse of
/// the file (`ParsedBlockEquivalence`). A block that does not come back the same becomes raw.
enum MarkdownImporter {
    /// Rounds of "find the wrong block, make it raw" before the whole text falls back to one raw block.
    private static let maxRepairRounds = 8

    static func load(_ markdown: String) -> RichImport {
        let source = MarkdownSourceText(markdown)
        let lines = SourceLines(source.body)
        let frontMatter = lines.frontMatterEnd()
        let bodyText = frontMatter == 0 ? source.body : lines.join(frontMatter..<lines.count)
        guard let parsed = RichImportSignposts.measure(RichImportSignposts.parse, { CmarkParser.editorBlocks(bodyText) }) else {
            MEGALog.log(level: .error, message: "[MarkdownImporter] cmark could not parse, the text stays raw. utf8Bytes=\(markdown.utf8.count)")
            return finish(.init(blocks: source.body.isEmpty ? [] : [.rawSource(source.body)], format: source.format), rawCount: 1)
        }
        var plan = RichImportSignposts.measure(RichImportSignposts.convert) {
            ImportPlan(lines: lines, frontMatterEnd: frontMatter, parsed: parsed)
        }
        // Pieces are keyed by text, so a repair round writes only what changed.
        var cache = InlineExportCache()
        for round in 0..<maxRepairRounds {
            let blocks = RichImportSignposts.measure(RichImportSignposts.convert) { plan.blocks() }
            var exporter = MarkdownExporter(blocks: blocks, previous: cache)
            let (body, reparsed) = RichImportSignposts.measure(RichImportSignposts.verify) {
                let body = exporter.markdown()
                // The front matter is not part of the parse it is compared with. The exporter writes "\n\n" after it.
                let checked = frontMatter == 0 ? body : String(decoding: body.utf8.dropFirst(plan.frontMatterText.utf8.count + 2), as: UTF8.self)
                return (body, CmarkParser.editorBlocks(checked)?.blocks ?? [])
            }
            cache = exporter.current
            if ParsedBlockEquivalence.isEquivalent(reparsed, parsed.blocks) {
                return RichImport(
                    document: RichDocument(blocks: blocks, format: source.format),
                    exported: MarkdownSourceText.file(body: body, format: source.format),
                    cache: cache,
                    rawBlockCount: plan.logRawBlocks(rounds: round),
                    repairRounds: round
                )
            }
            if !plan.markGroupsThatDoNotRoundTrip(round: round, reparsed: reparsed) { break }
        }
        MEGALog.log(level: .warning, message: "[MarkdownImporter] The rows do not write back the same text, the whole text stays raw. groups=\(plan.groups.count)")
        var blocks: [RichBlock] = []
        if frontMatter > 0 { blocks.append(.rawSource(plan.frontMatterText)) }
        if !lines.isBlank(frontMatter..<lines.count) { blocks.append(.rawSource(lines.join(lines.trimmed(frontMatter..<lines.count)))) }
        var result = finish(RichDocument(blocks: blocks, format: source.format), rawCount: blocks.count)
        result.repairRounds = maxRepairRounds
        return result
    }

    private static func finish(_ document: RichDocument, rawCount: Int) -> RichImport {
        var exporter = MarkdownExporter(blocks: document.blocks)
        let body = exporter.markdown()
        return RichImport(
            document: document,
            exported: MarkdownSourceText.file(body: body, format: document.format),
            cache: exporter.current,
            rawBlockCount: rawCount
        )
    }
}

// MARK: - Plan

/// Which top-level blocks become rich rows and which stay raw.
private struct ImportPlan {
    struct Group {
        var lines: ClosedRange<Int>
        /// Indexes into the parsed top-level blocks. More than one when blocks share a line.
        var blockIndexes: Range<Int>
        var rows: [RichBlock]?
    }

    let lines: SourceLines
    let frontMatterEnd: Int
    let frontMatterText: String
    private(set) var groups: [Group] = []
    private let parsed: [ParsedBlock]

    init(lines: SourceLines, frontMatterEnd: Int, parsed: (blocks: [ParsedBlock], lines: [ClosedRange<Int>])) {
        self.lines = lines
        self.frontMatterEnd = frontMatterEnd
        self.parsed = parsed.blocks
        frontMatterText = frontMatterEnd > 0 ? lines.join(0..<frontMatterEnd) : ""
        for (index, block) in parsed.blocks.enumerated() {
            let range = (parsed.lines[index].lowerBound + frontMatterEnd)...(parsed.lines[index].upperBound + frontMatterEnd)
            if let last = groups.last, range.lowerBound <= last.lines.upperBound {
                // Two blocks on one line (a paragraph cut by a table): keep both as one raw block.
                groups[groups.count - 1].lines = last.lines.lowerBound...max(last.lines.upperBound, range.upperBound)
                groups[groups.count - 1].blockIndexes = last.blockIndexes.lowerBound..<(index + 1)
                groups[groups.count - 1].rows = nil
                continue
            }
            var rows = RichBlockConversion.rows(for: block)
            // A link reference definition inside a converted block would be lost on save.
            if rows != nil, block.canHoldDefinition, range.contains(where: lines.looksLikeDefinition) {
                rows = nil
            }
            groups.append(Group(lines: range, blockIndexes: index..<(index + 1), rows: rows))
        }
    }

    /// Rows for the current plan: converted groups, then raw source for everything else.
    func blocks() -> [RichBlock] {
        var result: [RichBlock] = []
        if frontMatterEnd > 0 { result.append(.rawSource(frontMatterText)) }
        var pendingRaw: ClosedRange<Int>?
        func flushRaw() {
            if let raw = pendingRaw { result.append(.rawSource(lines.join(raw.lowerBound..<(raw.upperBound + 1)))) }
            pendingRaw = nil
        }
        func addRaw(_ range: Range<Int>) {
            let trimmed = lines.trimmed(range)
            guard !trimmed.isEmpty else { return }
            // Neighbour raw blocks join with the lines between them, so their bytes and spacing stay exact.
            pendingRaw = (pendingRaw?.lowerBound ?? trimmed.lowerBound)...(trimmed.upperBound - 1)
        }
        var cursor = frontMatterEnd
        for group in groups {
            addRaw(cursor..<group.lines.lowerBound)
            if let rows = group.rows {
                flushRaw()
                Self.appendKeepingListsApart(rows, to: &result)
            } else {
                addRaw(group.lines.lowerBound..<(group.lines.upperBound + 1))
            }
            cursor = group.lines.upperBound + 1
        }
        addRaw(cursor..<lines.count)
        flushRaw()
        return result
    }

    /// Two lists of the same kind next to each other would merge into one list on save, and two quotes into one quote.
    /// An empty paragraph between them keeps them apart: the exporter starts a new list or quote after it.
    private static func appendKeepingListsApart(_ rows: [RichBlock], to result: inout [RichBlock]) {
        // The list before may end with nested items. Its top-level kind decides.
        let previousTop = result.reversed().prefix { $0.listItem != nil }.first { $0.listItem?.indent == 0 }?.listItem
        if case .listItem(let first, _)? = rows.first, let previousTop, previousTop.isOrdered == first.isOrdered, first.startNumber == nil {
            result.append(.paragraph(RichText()))
        }
        if case .quote? = rows.first, case .quote? = result.last {
            result.append(.paragraph(RichText()))
        }
        result += rows
    }

    /// Makes raw the groups that caused a difference. Returns false when there is nothing left to try.
    mutating func markGroupsThatDoNotRoundTrip(round: Int, reparsed: [ParsedBlock]) -> Bool {
        if round == 0 {
            // Most differences come from one block alone. Check each converted block by itself.
            var changed = false
            for index in groups.indices {
                guard let rows = groups[index].rows else { continue }
                var exporter = MarkdownExporter(blocks: rows)
                let alone = CmarkParser.editorBlocks(exporter.markdown())?.blocks ?? []
                if !ParsedBlockEquivalence.isEquivalent(alone, Array(parsed[groups[index].blockIndexes])) {
                    groups[index].rows = nil
                    changed = true
                }
            }
            if changed { return true }
        }
        // Blocks that change only next to each other: make the first different block and the one before it raw.
        let common = min(parsed.count, reparsed.count)
        let different = (0..<common).first { !ParsedBlockEquivalence.isEquivalent(parsed[$0], reparsed[$0]) } ?? common
        guard let group = groups.lastIndex(where: { $0.blockIndexes.lowerBound <= different }) else { return false }
        let before = groups[..<group].lastIndex { $0.rows != nil }
        guard groups[group].rows != nil || before != nil else { return false }
        groups[group].rows = nil
        if let before { groups[before].rows = nil }
        return true
    }

    func logRawBlocks(rounds: Int) -> Int {
        let raw = groups.count { $0.rows == nil }
        if raw > 0 || rounds > 0 {
            MEGALog.log(level: .debug, message: "[MarkdownImporter] Blocks kept as read-only raw source. raw=\(raw) groups=\(groups.count) repairRounds=\(rounds)")
        }
        return raw
    }
}

private extension ParsedBlock {
    /// Blocks whose lines can hold a link reference definition that the parse removed.
    var canHoldDefinition: Bool {
        switch kind {
        case .paragraph, .heading, .list, .blockQuote: true
        case .codeBlock, .table, .thematicBreak, .image: false
        }
    }
}
