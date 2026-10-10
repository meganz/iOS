import FileProvider

/// Records in a folder's snapshot what an enumeration of the folder delivers to the system.
public protocol FileProviderEnumerationSnapshotUseCaseProtocol: Sendable {
    /// Adds or updates the delivered children, creating the snapshot if there is none, even for an empty folder.
    ///
    /// Children the enumeration did not list are kept. A snapshot may hold more than the system, never less: a child
    /// missing from it could never be reported as deleted.
    func didEnumerate(_ items: [FileProviderItemEntity], in containerIdentifier: NSFileProviderItemIdentifier) async throws
}

public struct FileProviderEnumerationSnapshotUseCase<S: FileProviderSnapshotRepositoryProtocol>: FileProviderEnumerationSnapshotUseCaseProtocol {
    private let snapshotRepo: S

    public init(snapshotRepo: S) {
        self.snapshotRepo = snapshotRepo
    }

    public func didEnumerate(_ items: [FileProviderItemEntity], in containerIdentifier: NSFileProviderItemIdentifier) async throws {
        let versionHashes = Dictionary(items.map { ($0.identifier, $0.versionHash) }) { _, last in last }
        try await snapshotRepo.updateSnapshot(of: containerIdentifier) { snapshot in
            var updated = snapshot ?? FileProviderSnapshotEntity()
            updated.versionHashes.merge(versionHashes) { _, new in new }
            snapshot = updated
        }
    }
}
