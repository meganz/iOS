import MEGAMarkdown

/// The preview rows of each raw row, by row identity, and the link reference definitions they were rendered with.
/// A replace keeps old identities in order, so an identity can hold a new block. The cache keeps the source
/// it rendered and renders again when the source differs.
struct RichRawRenderCache: Sendable {
    /// What `update` found.
    enum Update: Equatable, Sendable {
        /// The definitions are the same. Only new or changed raw rows were rendered.
        case kept
        /// The definitions changed, so every raw row was rendered again. Every item must reload.
        case renderedAll
    }

    /// A raw row in the model.
    struct RawRow: Sendable {
        var id: RichRowID
        var source: String
    }

    private struct Entry: Sendable {
        var source: String
        var rows: [PreviewRow]
    }

    private var entries: [RichRowID: Entry] = [:]
    private(set) var definitions: String

    /// The cache after a load, which rendered `rows` with `definitions`.
    init(raw: [RawRow], rows: [RichRowID: [PreviewRow]], definitions: String) {
        self.definitions = definitions
        for row in raw {
            entries[row.id] = Entry(source: row.source, rows: rows[row.id] ?? Self.render(row.source, definitions: definitions))
        }
    }

    /// The preview rows of a raw row. Empty when the block shows nothing: the row then shows its source, dimmed.
    func previewRows(for id: RichRowID) -> [PreviewRow]? {
        entries[id]?.rows
    }

    /// The items a raw row takes in the list: one per preview row, at least one.
    func itemCount(for id: RichRowID) -> Int {
        max(1, entries[id]?.rows.count ?? 1)
    }

    /// Called after a change. `oldIDs` are the identities of the replaced rows. `newRaw` are the raw rows among
    /// the new rows. When a raw row came, went or changed, the definitions are read again (once).
    /// If they differ, every raw row of `allRaw` is rendered again.
    mutating func update(
        removing oldIDs: some Sequence<RichRowID>,
        adding newRaw: [RawRow],
        allRaw: () -> [RawRow],
        definitions newDefinitions: () -> String
    ) -> Update {
        let removed = oldIDs.filter { id in entries[id] != nil && !newRaw.contains { $0.id == id } }
        let changed = newRaw.filter { raw in entries[raw.id].map { !$0.source.hasSameBytes(as: raw.source) } ?? true }
        guard !removed.isEmpty || !changed.isEmpty else { return .kept }
        for id in removed { entries[id] = nil }
        let definitions = newDefinitions()
        guard definitions.hasSameBytes(as: self.definitions) else {
            self.definitions = definitions
            entries = [:]
            for raw in allRaw() { entries[raw.id] = Entry(source: raw.source, rows: Self.render(raw.source, definitions: definitions)) }
            return .renderedAll
        }
        for raw in changed { entries[raw.id] = Entry(source: raw.source, rows: Self.render(raw.source, definitions: definitions)) }
        return .kept
    }

    static func render(_ source: String, definitions: String) -> [PreviewRow] {
        PreviewRows.rows(forMarkdown: source, softBreak: .lineBreak, definitions: definitions)
    }
}
