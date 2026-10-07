import Foundation

/// What the editor knows about its last export. The dirty check compares exports, not the document and the file:
/// an untouched file never saves, even when its Markdown would write differently.
struct RichExportState: Sendable {
    /// The text the editor was loaded from.
    let loadedMarkdown: String
    /// The last Markdown given out, or the export at load.
    private(set) var lastExported: String
    /// Inline pieces of the last export, so the next export writes only changed blocks.
    private(set) var cache: InlineExportCache
    /// The editor version of `lastExported`.
    private(set) var exportedVersion = 0
    /// True after an export was given out. From then on the loaded text is no longer the echo of the load.
    private(set) var hasGivenOutExport = false

    init(loadedMarkdown: String, loaded: RichImport) {
        self.init(loadedMarkdown: loadedMarkdown, exported: loaded.exported, cache: loaded.cache)
    }

    /// `exportedVersion` is -1 for a file that does not exist yet, so its first export counts as a change.
    init(loadedMarkdown: String, exported: String, cache: InlineExportCache, exportedVersion: Int = 0) {
        self.loadedMarkdown = loadedMarkdown
        lastExported = exported
        self.cache = cache
        self.exportedVersion = exportedVersion
    }

    /// Keeps the result. Returns the Markdown when it differs from the last export.
    mutating func accept(_ markdown: String, cache newCache: InlineExportCache, version: Int) -> String? {
        cache = newCache
        exportedVersion = version
        guard !markdown.hasSameBytes(as: lastExported) else { return nil }
        lastExported = markdown
        hasGivenOutExport = true
        return markdown
    }

    /// The loaded text counts until the first export is given out. After that it is a revert from outside.
    func holds(_ markdown: String) -> Bool {
        (!hasGivenOutExport && markdown.hasSameBytes(as: loadedMarkdown)) || markdown.hasSameBytes(as: lastExported)
    }
}

/// An export that can run off the main thread. Make it with `RichEditor.makeExportJob()`.
struct RichExportJob: Sendable {
    let document: RichDocument
    let cache: InlineExportCache
    let version: Int

    func run() -> RichExportResult {
        var cache = cache
        let markdown = RichMarkdownConverter.markdown(from: document, cache: &cache)
        return RichExportResult(markdown: markdown, cache: cache, version: version)
    }
}

struct RichExportResult: Sendable {
    let markdown: String
    let cache: InlineExportCache
    let version: Int
}

extension RichEditor {
    /// True when the document changed since the last export. It may still write the same Markdown (after undo).
    var hasUnexportedChanges: Bool {
        version != export.exportedVersion
    }

    /// True when `markdown` is the text the editor holds: the last export, or the loaded text before any export.
    /// The UI uses it to tell its own save from a new file.
    func holds(_ markdown: String) -> Bool {
        export.holds(markdown)
    }

    /// Exports now. Returns the Markdown when it differs from the last export, else nil.
    mutating func exportChanges() -> String? {
        guard hasUnexportedChanges else { return nil }
        let result = makeExportJob().run()
        return export.accept(result.markdown, cache: result.cache, version: result.version)
    }

    func makeExportJob() -> RichExportJob {
        RichExportJob(document: document, cache: export.cache, version: version)
    }

    /// Takes a background export. Returns the Markdown when it is still current and differs from the last export.
    /// A result for an older version is dropped, but its cache pieces are kept: they are keyed by text.
    mutating func finishExport(_ result: RichExportResult) -> String? {
        guard result.version == version else {
            export.keepCache(result.cache)
            return nil
        }
        return export.accept(result.markdown, cache: result.cache, version: result.version)
    }
}

extension RichExportState {
    fileprivate mutating func keepCache(_ newCache: InlineExportCache) {
        cache = newCache
    }
}
