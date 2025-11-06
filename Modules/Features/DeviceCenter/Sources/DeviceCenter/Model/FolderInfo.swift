import Foundation

struct FolderInfo {
    var files: Int
    var folders: Int
    var totalSize: UInt64
    /// Date of addition of the current folder. This value is optional as it is not required for devices.
    var added: Date?

    static var emptyFolder: Self {
        .init(
            files: 0,
            folders: 0,
            totalSize: 0,
            added: nil
        )
    }
}
