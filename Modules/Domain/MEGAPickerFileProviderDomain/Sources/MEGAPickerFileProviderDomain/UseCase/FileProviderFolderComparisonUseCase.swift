import FileProvider
import MEGADomain

/// Finds the children of a folder that changed since the system last received them, and queues them for the
/// working set's change enumeration. Runs when the system asks for an enumerator of the folder.
public protocol FileProviderFolderComparisonUseCaseProtocol: Sendable {
    /// Whether the system has enumerated the container, so that there is something to compare. A file never has
    /// been: the system asks for a file's enumerator when the file is opened, but never enumerates it.
    func hasSnapshot(of containerIdentifier: NSFileProviderItemIdentifier) async throws -> Bool

    /// Queues the children whose version differs from the folder's snapshot, and signals the working set when any
    /// was queued. Does nothing for a folder without a snapshot, which the system has not enumerated yet.
    /// - Parameter reportsRemovals: Whether children missing from the folder are queued. Pass `false` while the node
    ///   tree may be behind the server, where a missing child is not necessarily gone.
    /// - Returns: Whether any child was queued.
    @discardableResult
    func compareChildren(of containerIdentifier: NSFileProviderItemIdentifier, reportsRemovals: Bool) async throws -> Bool
}

public struct FileProviderFolderComparisonUseCase: FileProviderFolderComparisonUseCaseProtocol {
    private static var pageSize: Int { 200 }

    private let itemUseCase: any FileProviderItemUseCaseProtocol
    private let snapshotRepo: any FileProviderSnapshotRepositoryProtocol
    private let changeQueueRepo: any FileProviderChangeQueueRepositoryProtocol
    private let workingSetSignalRepo: any FileProviderWorkingSetSignalRepositoryProtocol

    public init(
        itemUseCase: any FileProviderItemUseCaseProtocol,
        snapshotRepo: any FileProviderSnapshotRepositoryProtocol,
        changeQueueRepo: any FileProviderChangeQueueRepositoryProtocol,
        workingSetSignalRepo: any FileProviderWorkingSetSignalRepositoryProtocol
    ) {
        self.itemUseCase = itemUseCase
        self.snapshotRepo = snapshotRepo
        self.changeQueueRepo = changeQueueRepo
        self.workingSetSignalRepo = workingSetSignalRepo
    }

    public func hasSnapshot(of containerIdentifier: NSFileProviderItemIdentifier) async throws -> Bool {
        try await snapshotRepo.snapshot(of: containerIdentifier) != nil
    }

    @discardableResult
    public func compareChildren(of containerIdentifier: NSFileProviderItemIdentifier, reportsRemovals: Bool) async throws -> Bool {
        guard let snapshot = try await snapshotRepo.snapshot(of: containerIdentifier) else {
            return false
        }

        let changedIdentifiers: [NSFileProviderItemIdentifier]
        do {
            let versionHashes = try await currentVersionHashes(of: containerIdentifier)
            let addedOrChanged = versionHashes.filter { snapshot.versionHashes[$0.key] != $0.value }.map(\.key)
            let removed = reportsRemovals ? snapshot.versionHashes.keys.filter { versionHashes[$0] == nil } : []
            changedIdentifiers = addedOrChanged + removed
        } catch let error as NSFileProviderError where error.code == .noSuchItem
                    && reportsRemovals && containerIdentifier != .rootContainer && containerIdentifier != .trashContainer {
            // The folder itself is gone or no longer listed; reporting it is enough, the system drops its children.
            changedIdentifiers = [containerIdentifier]
        }

        guard !changedIdentifiers.isEmpty else {
            return false
        }
        try await changeQueueRepo.append(changedIdentifiers.map {
            FileProviderChangeEntity(identifier: $0, folderIdentifier: containerIdentifier)
        })
        try await workingSetSignalRepo.signalWorkingSet()
        return true
    }

    // MARK: - Private

    private func currentVersionHashes(of containerIdentifier: NSFileProviderItemIdentifier) async throws -> [NSFileProviderItemIdentifier: UInt64] {
        var versionHashes: [NSFileProviderItemIdentifier: UInt64] = [:]
        var offset = 0
        while true {
            try Task.checkCancellation()
            let items = try await itemUseCase.children(
                of: containerIdentifier,
                page: SearchPageEntity(startingOffset: offset, pageSize: Self.pageSize)
            )
            for item in items {
                versionHashes[item.identifier] = item.versionHash
            }
            guard items.count == Self.pageSize else {
                return versionHashes
            }
            offset += items.count
        }
    }
}
