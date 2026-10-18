import MEGASdk

extension MEGASdk {
    /// The single path component a node's name takes on disk. A cloud name is arbitrary: it can hold `/` or
    /// be `..`, and appended verbatim it names something outside the folder it was meant for. This applies
    /// the SDK's own escaping (`..` → `%2e%2e`, `/` → `%2f`, …), which is also how the SDK names a file when
    /// it is handed a folder to download into, so both paths agree on the name.
    func fileSystemName(for name: String, destinationPath: String) -> String {
        escapeFsIncompatible(name, destinationPath: destinationPath) ?? Self.fallbackFileSystemName(for: name)
    }

    /// Only reached without a live `MegaApi`; keeps the result a single component all the same.
    private static func fallbackFileSystemName(for name: String) -> String {
        switch name {
        case "..": "%2e%2e"
        case ".": "%2e"
        default: name.replacingOccurrences(of: "/", with: "%2f")
        }
    }
}
