import FileProvider

/// The children the system holds for one folder, and the version of each it was given.
///
/// Every folder the system has enumerated has one. Comparing it with the folder's current children finds the changes
/// the system has yet to be told about.
public struct FileProviderSnapshotEntity: Sendable, Equatable {
    /// Each child's `FileProviderItemEntity.versionHash` as it was delivered.
    public var versionHashes: [NSFileProviderItemIdentifier: UInt64]

    public init(versionHashes: [NSFileProviderItemIdentifier: UInt64] = [:]) {
        self.versionHashes = versionHashes
    }
}
