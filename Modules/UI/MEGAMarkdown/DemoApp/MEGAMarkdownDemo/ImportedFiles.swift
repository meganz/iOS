import Foundation

/// Markdown files that other apps shared with the demo. The demo keeps a copy in `Documents/Imported`.
enum ImportedFiles {
    static let folder = URL.documentsDirectory.appending(path: "Imported")
    static let extensions = ["md", "markdown"]

    static func isMarkdown(_ url: URL) -> Bool {
        extensions.contains(url.pathExtension.lowercased())
    }

    /// Copies the shared file and returns the copy. A name that exists gets a number: `a 2.md`.
    static func importFile(from source: URL) throws -> URL {
        let isScoped = source.startAccessingSecurityScopedResource()
        defer { if isScoped { source.stopAccessingSecurityScopedResource() } }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var target = folder.appending(path: source.lastPathComponent)
        var number = 2
        while FileManager.default.fileExists(atPath: target.path) {
            let name = source.deletingPathExtension().lastPathComponent
            target = folder.appending(path: "\(name) \(number).\(source.pathExtension)")
            number += 1
        }
        try FileManager.default.copyItem(at: source, to: target)
        return target
    }

    static func entries() -> [TestFileEntry] {
        TestFileEntry.children(of: folder).filter { !$0.isFolder && isMarkdown($0.url) }
    }

    static func entry(for url: URL) -> TestFileEntry {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return TestFileEntry(url: url, isFolder: false, byteCount: size)
    }
}
