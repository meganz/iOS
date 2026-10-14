import FileProvider
import MEGADomain

/// Applies the changes the user makes in Files to the cloud drive: creating folders, renaming, moving, moving to and
/// out of the trash, and deleting. Each item returned is recorded in the folders' snapshots, since the system now
/// holds it.
///
/// Besides the errors listed for each call, every write throws `NSFileProviderError(.cannotSynchronize)` while a
/// business account is expired.
public protocol FileProviderItemActionUseCaseProtocol: Sendable {
    /// Creates a folder named `name` in a container, and gives it an empty snapshot: the system never enumerates a
    /// folder it created, so the snapshot is what gets the children added elsewhere reported.
    func createFolder(
        named name: String,
        in parentIdentifier: NSFileProviderItemIdentifier,
        reusesExistingFolder: Bool
    ) async throws -> FileProviderItemEntity

    /// Renames and moves an item; `nil` keeps the name or the parent as it is. An item that ends up directly in the
    /// trash keeps its name, like in the legacy extension: the system renames an item it trashes when its trash
    /// holds one of the same name.
    func modifyItem(
        _ identifier: NSFileProviderItemIdentifier,
        name: String?,
        parentIdentifier: NSFileProviderItemIdentifier?
    ) async throws -> FileProviderItemEntity

    /// Deletes an item in the rubbish bin for good. Does nothing when the item is not there.
    func deleteItem(_ identifier: NSFileProviderItemIdentifier, recursive: Bool) async throws
}

public struct FileProviderItemActionUseCase: FileProviderItemActionUseCaseProtocol {
    private let itemUseCase: any FileProviderItemUseCaseProtocol
    private let nodeRepo: any NodeRepositoryProtocol
    private let nodeActionRepo: any NodeActionRepositoryProtocol
    private let snapshotRepo: any FileProviderSnapshotRepositoryProtocol

    public init(
        itemUseCase: any FileProviderItemUseCaseProtocol,
        nodeRepo: any NodeRepositoryProtocol,
        nodeActionRepo: any NodeActionRepositoryProtocol,
        snapshotRepo: any FileProviderSnapshotRepositoryProtocol
    ) {
        self.itemUseCase = itemUseCase
        self.nodeRepo = nodeRepo
        self.nodeActionRepo = nodeActionRepo
        self.snapshotRepo = snapshotRepo
    }

    public func createFolder(
        named name: String,
        in parentIdentifier: NSFileProviderItemIdentifier,
        reusesExistingFolder: Bool
    ) async throws -> FileProviderItemEntity {
        try await withFileProviderErrors {
            let parent = try folderNode(for: parentIdentifier)
            let folder: NodeEntity
            if reusesExistingFolder, let existingFolder = nodeRepo.childNodeNamed(name: name, in: parent.handle), existingFolder.isFolder {
                folder = existingFolder
            } else {
                folder = try await nodeActionRepo.createFolder(name: name, parent: parent)
            }
            let item = try itemUseCase.item(for: NSFileProviderItemIdentifier(folder.base64Handle))
            await record(item, movedFrom: nil)
            // Kept when there is one already, for a folder reused after the system enumerated it.
            try? await snapshotRepo.updateSnapshot(of: item.identifier) { $0 = $0 ?? FileProviderSnapshotEntity() }
            return item
        }
    }

    public func modifyItem(
        _ identifier: NSFileProviderItemIdentifier,
        name: String?,
        parentIdentifier: NSFileProviderItemIdentifier?
    ) async throws -> FileProviderItemEntity {
        try await withFileProviderErrors {
            let item = try itemUseCase.item(for: identifier)
            if let parentIdentifier, parentIdentifier != item.parentIdentifier {
                try await move(item, to: parentIdentifier)
            }
            if let name, name != item.node.name, (parentIdentifier ?? item.parentIdentifier) != .trashContainer {
                _ = try await nodeActionRepo.rename(node: item.node, name: name)
            }
            let modifiedItem = try itemUseCase.item(for: identifier)
            await record(modifiedItem, movedFrom: item.parentIdentifier)
            return modifiedItem
        }
    }

    public func deleteItem(_ identifier: NSFileProviderItemIdentifier, recursive: Bool) async throws {
        try await withFileProviderErrors {
            let item: FileProviderItemEntity
            do {
                item = try itemUseCase.item(for: identifier)
            } catch let error as NSFileProviderError where error.code == .noSuchItem {
                return
            }
            guard nodeRepo.isInRubbishBin(node: item.node) else {
                throw NSFileProviderError(.deletionRejected)
            }
            if !recursive, let childCount = item.childCount, childCount > 0 {
                throw NSFileProviderError(.directoryNotEmpty)
            }
            try await nodeActionRepo.delete(node: item.node)
            await removeFromSnapshots(item)
        }
    }

    // MARK: - Private

    private func move(_ item: FileProviderItemEntity, to parentIdentifier: NSFileProviderItemIdentifier) async throws {
        guard parentIdentifier != .trashContainer else {
            _ = try await nodeActionRepo.trash(node: item.node)
            return
        }
        let parent = try folderNode(for: parentIdentifier)
        if item.parentIdentifier == .trashContainer, !nodeRepo.isInRubbishBin(node: parent), canBeRestored(item.node) {
            _ = try await nodeActionRepo.untrash(node: item.node)
        } else {
            _ = try await nodeActionRepo.move(node: item.node, toParent: parent)
        }
    }

    /// Whether the folder a node in the rubbish bin was moved there from is still a folder outside the rubbish bin.
    private func canBeRestored(_ node: NodeEntity) -> Bool {
        guard let parent = nodeRepo.nodeForHandle(node.restoreParentHandle) else {
            return false
        }
        return parent.isFolder && !nodeRepo.isInRubbishBin(node: parent)
    }

    /// - Throws: `NSFileProviderError(.noSuchItem)` when the container is not a folder that exists.
    private func folderNode(for identifier: NSFileProviderItemIdentifier) throws -> NodeEntity {
        let node = try itemUseCase.item(for: identifier).node
        guard node.isFolder else {
            throw NSFileProviderError(.noSuchItem)
        }
        return node
    }

    /// Records the item in its parent's snapshot, and removes it from the snapshot of the folder it was moved from.
    /// Failing to is no reason to fail the write that was made: an out-of-date snapshot only gets the item reported
    /// again.
    private func record(_ item: FileProviderItemEntity, movedFrom formerParentIdentifier: NSFileProviderItemIdentifier?) async {
        let versionHash = item.versionHash
        try? await snapshotRepo.updateSnapshot(of: item.parentIdentifier) { $0?.versionHashes[item.identifier] = versionHash }
        if let formerParentIdentifier, formerParentIdentifier != item.parentIdentifier {
            try? await snapshotRepo.updateSnapshot(of: formerParentIdentifier) { $0?.versionHashes[item.identifier] = nil }
        }
    }

    /// Removes a deleted item from its parent's snapshot, along with a folder's own snapshot. Best effort, like
    /// `record(_:movedFrom:)`.
    private func removeFromSnapshots(_ item: FileProviderItemEntity) async {
        try? await snapshotRepo.updateSnapshot(of: item.parentIdentifier) { $0?.versionHashes[item.identifier] = nil }
        try? await snapshotRepo.removeSnapshot(of: item.identifier)
    }

    /// Turns the failures the system has a meaning for into its errors; it retries after any other.
    private func withFileProviderErrors<T>(_ body: () async throws -> T) async throws -> T {
        do {
            return try await body()
        } catch CreateFolderErrorEntity.businessExpired, RenameNodeErrorEntity.businessExpired, MoveNodeErrorEntity.businessExpired {
            throw NSFileProviderError(.cannotSynchronize)
        } catch RemoveNodeErrorEntity.masterOnly {
            throw NSFileProviderError(.deletionRejected)
        }
    }
}
