import FileProvider

/// Turns the queued changes into what the working set's change enumeration reports, and keeps the snapshots in step
/// with what the system then holds.
public protocol FileProviderChangesUseCaseProtocol: Sendable {
    /// The working set's sync anchor: just after every change queued so far.
    func currentAnchor() async throws -> NSFileProviderSyncAnchor

    /// The changes queued after `anchor`, read from the nodes as they are now.
    ///
    /// A queued item is reported as updated when an enumeration would list it, and as deleted otherwise. The folders
    /// the items were found in are reported too, since their child counts may have changed.
    /// - Parameter limit: The most queued changes to read; the folders come on top.
    /// - Throws: `NSFileProviderError(.syncAnchorExpired)` when `anchor` was not handed out by this queue or the
    ///   changes after it are gone. After any other error the system can ask again from the same anchor.
    func changes(from anchor: NSFileProviderSyncAnchor, limit: Int) async throws -> FileProviderChangeSetEntity
}

public struct FileProviderChangesUseCase: FileProviderChangesUseCaseProtocol {
    private let itemUseCase: any FileProviderItemUseCaseProtocol
    private let snapshotRepo: any FileProviderSnapshotRepositoryProtocol
    private let changeQueueRepo: any FileProviderChangeQueueRepositoryProtocol

    public init(
        itemUseCase: any FileProviderItemUseCaseProtocol,
        snapshotRepo: any FileProviderSnapshotRepositoryProtocol,
        changeQueueRepo: any FileProviderChangeQueueRepositoryProtocol
    ) {
        self.itemUseCase = itemUseCase
        self.snapshotRepo = snapshotRepo
        self.changeQueueRepo = changeQueueRepo
    }

    public func currentAnchor() async throws -> NSFileProviderSyncAnchor {
        try NSFileProviderSyncAnchor(try await changeQueueRepo.currentAnchor())
    }

    public func changes(from anchor: NSFileProviderSyncAnchor, limit: Int) async throws -> FileProviderChangeSetEntity {
        guard let changeAnchor = anchor.changeAnchor else {
            throw NSFileProviderError(.syncAnchorExpired)
        }
        let batch: FileProviderChangeBatchEntity
        do {
            batch = try await changeQueueRepo.changes(since: changeAnchor, limit: limit)
        } catch FileProviderChangeQueueErrorEntity.anchorExpired {
            throw NSFileProviderError(.syncAnchorExpired)
        }

        var foldersByIdentifier: [NSFileProviderItemIdentifier: Set<NSFileProviderItemIdentifier>] = [:]
        var candidates = OrderedIdentifiers()
        for change in batch.changes {
            foldersByIdentifier[change.identifier, default: []].insert(change.folderIdentifier)
            candidates.append(change.identifier)
            candidates.append(change.folderIdentifier)
        }

        var updatedItems: [FileProviderItemEntity] = []
        var deletedIdentifiers: [NSFileProviderItemIdentifier] = []
        // Grows while it is walked: a moved item's new parent is added to it.
        var index = 0
        while index < candidates.identifiers.count {
            let identifier = candidates.identifiers[index]
            index += 1
            guard let item = try itemUseCase.presentableItem(for: identifier) else {
                deletedIdentifiers.append(identifier)
                continue
            }
            updatedItems.append(item)
            if let folders = foldersByIdentifier[identifier], !folders.contains(item.parentIdentifier) {
                candidates.append(item.parentIdentifier)
            }
        }

        try await updateSnapshots(updatedItems: updatedItems, deletedIdentifiers: deletedIdentifiers, foldersByIdentifier: foldersByIdentifier)
        return FileProviderChangeSetEntity(
            updatedItems: Self.parentsFirst(updatedItems),
            deletedIdentifiers: deletedIdentifiers,
            anchor: try NSFileProviderSyncAnchor(batch.nextAnchor),
            moreComing: batch.hasMore
        )
    }

    // MARK: - Private

    /// Identifiers in the order they were first added, each once.
    private struct OrderedIdentifiers {
        private(set) var identifiers: [NSFileProviderItemIdentifier] = []
        private var added: Set<NSFileProviderItemIdentifier> = []

        mutating func append(_ identifier: NSFileProviderItemIdentifier) {
            if added.insert(identifier).inserted {
                identifiers.append(identifier)
            }
        }
    }

    /// What the delivered changes do to one folder's snapshot.
    private struct SnapshotEdit: Sendable {
        var versionHashes: [NSFileProviderItemIdentifier: UInt64] = [:]
        var removedIdentifiers: Set<NSFileProviderItemIdentifier> = []
    }

    /// Records the delivered changes in the snapshots. A folder without a snapshot gets none: its enumeration will
    /// create it.
    private func updateSnapshots(
        updatedItems: [FileProviderItemEntity],
        deletedIdentifiers: [NSFileProviderItemIdentifier],
        foldersByIdentifier: [NSFileProviderItemIdentifier: Set<NSFileProviderItemIdentifier>]
    ) async throws {
        var edits: [NSFileProviderItemIdentifier: SnapshotEdit] = [:]
        // The root and the trash are no folder's children, though their items name the root as parent.
        for item in updatedItems where item.identifier != .rootContainer && item.identifier != .trashContainer {
            edits[item.parentIdentifier, default: SnapshotEdit()].versionHashes[item.identifier] = item.versionHash
            for folder in foldersByIdentifier[item.identifier] ?? [] where folder != item.parentIdentifier {
                edits[folder, default: SnapshotEdit()].removedIdentifiers.insert(item.identifier)
            }
        }
        for identifier in deletedIdentifiers {
            for folder in foldersByIdentifier[identifier] ?? [] {
                edits[folder, default: SnapshotEdit()].removedIdentifiers.insert(identifier)
            }
        }
        // The system drops a deleted folder's children along with it.
        for identifier in deletedIdentifiers {
            edits[identifier] = nil
            try await snapshotRepo.removeSnapshot(of: identifier)
        }

        for (containerIdentifier, edit) in edits {
            try await snapshotRepo.updateSnapshot(of: containerIdentifier) { snapshot in
                guard var updated = snapshot else { return }
                updated.versionHashes.merge(edit.versionHashes) { _, new in new }
                for identifier in edit.removedIdentifiers {
                    updated.versionHashes[identifier] = nil
                }
                snapshot = updated
            }
        }
    }

    /// Orders the items so that each comes after its parent when both are in the batch.
    private static func parentsFirst(_ items: [FileProviderItemEntity]) -> [FileProviderItemEntity] {
        var ordered: [FileProviderItemEntity] = []
        var remaining = items
        while !remaining.isEmpty {
            let remainingIdentifiers = Set(remaining.map(\.identifier))
            let isReady: (FileProviderItemEntity) -> Bool = {
                $0.parentIdentifier == $0.identifier || !remainingIdentifiers.contains($0.parentIdentifier)
            }
            let ready = remaining.filter(isReady)
            guard !ready.isEmpty else {
                // Only a cycle gets here, which a node tree cannot have.
                return ordered + remaining
            }
            ordered += ready
            remaining.removeAll(where: isReady)
        }
        return ordered
    }
}
