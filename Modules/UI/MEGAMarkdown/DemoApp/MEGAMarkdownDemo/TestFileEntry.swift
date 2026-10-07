import Foundation

/// One file or folder of the synced `TestFiles` folder.
struct TestFileEntry: Identifiable, Hashable {
    let url: URL
    let isFolder: Bool
    let byteCount: Int

    var id: URL { url }
    var name: String { url.lastPathComponent }

    /// Image files sit next to the Markdown files that link to them. They open as images, like on GitHub.
    var isImage: Bool {
        ["png", "jpg", "jpeg", "gif", "heic", "webp"].contains(url.pathExtension.lowercased())
    }

    /// `TestFilesSync` writes the test-file repo here.
    static let syncedRoot = URL.documentsDirectory.appending(path: "TestFiles")

    /// Nil before the first sync.
    static var root: URL? {
        FileManager.default.fileExists(atPath: syncedRoot.path) ? syncedRoot : nil
    }

    static func folder(_ url: URL) -> TestFileEntry {
        TestFileEntry(url: url, isFolder: true, byteCount: 0)
    }

    /// True for a file below `TestFiles`. Imported files are not.
    var isTestFile: Bool {
        guard let root = Self.root else { return false }
        return url.standardizedFileURL.path.hasPrefix(root.standardizedFileURL.path + "/")
    }

    /// The path below `TestFiles`, for example `tables/basic-alignment.md`. Other files give their name.
    var relativePath: String {
        guard isTestFile, let root = Self.root else { return name }
        let rootPath = root.standardizedFileURL.path + "/"
        return String(url.standardizedFileURL.path.dropFirst(rootPath.count))
    }

    /// Folders first, then files, each sorted by name like Finder.
    static func children(of folder: URL) -> [TestFileEntry] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey]
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: keys, options: .skipsHiddenFiles)) ?? []
        let entries = urls.map { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            return TestFileEntry(url: url, isFolder: values?.isDirectory ?? false, byteCount: values?.fileSize ?? 0)
        }
        return entries.sorted { lhs, rhs in
            if lhs.isFolder != rhs.isFolder {
                return lhs.isFolder
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}
