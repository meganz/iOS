import FileProvider
import MEGADomain

/// Keeps a `FileProviderSnapshotEntity` for each folder the system has enumerated.
public protocol FileProviderSnapshotRepositoryProtocol: RepositoryProtocol, Sendable {
    /// `nil` when the system has never enumerated the folder.
    func snapshot(of containerIdentifier: NSFileProviderItemIdentifier) async throws -> FileProviderSnapshotEntity?
    /// Changes the folder's snapshot in place; `nil` stands for no snapshot, both in and out. Updates made
    /// through the same repository never overwrite each other.
    func updateSnapshot(
        of containerIdentifier: NSFileProviderItemIdentifier,
        _ update: @Sendable (inout FileProviderSnapshotEntity?) -> Void
    ) async throws
    /// Does nothing when the folder has no snapshot.
    func removeSnapshot(of containerIdentifier: NSFileProviderItemIdentifier) async throws
    /// The folders that have a snapshot.
    func containerIdentifiers() async throws -> [NSFileProviderItemIdentifier]
}
