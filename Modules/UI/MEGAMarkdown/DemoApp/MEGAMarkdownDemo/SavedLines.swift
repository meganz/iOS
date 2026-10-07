import Foundation

/// The last top line the reader showed for each file. A file reopens at that line.
enum SavedLines {
    private static let key = "savedTopLines"

    static func line(for url: URL) -> Int? {
        let lines = UserDefaults.standard.dictionary(forKey: key) as? [String: Int]
        return lines?[name(of: url)]
    }

    static func save(_ line: Int, for url: URL) {
        var lines = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] ?? [:]
        lines[name(of: url)] = line
        UserDefaults.standard.set(lines, forKey: key)
    }

    /// The path below `Documents`. The app container path changes between installs.
    private static func name(of url: URL) -> String {
        let documents = URL.documentsDirectory.standardizedFileURL.path + "/"
        let path = url.standardizedFileURL.path
        return path.hasPrefix(documents) ? String(path.dropFirst(documents.count)) : path
    }
}
