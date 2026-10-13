import AsyncAlgorithms
import FileProvider
import MEGADomain

/// Queues the node updates the SDK reports while the extension runs, for the working set's change enumeration, so
/// that a folder Files shows picks up remote changes without being opened again.
public protocol FileProviderNodeUpdatesUseCaseProtocol: Sendable {
    /// Queues each updated node that can change what the system shows, and signals the working set once the updates
    /// have paused for `signalDelay`. Returns when the updates end.
    func queueNodeUpdates() async throws
}

public struct FileProviderNodeUpdatesUseCase: FileProviderNodeUpdatesUseCaseProtocol {
    private let nodeRepo: any NodeRepositoryProtocol
    private let snapshotRepo: any FileProviderSnapshotRepositoryProtocol
    private let changeQueueRepo: any FileProviderChangeQueueRepositoryProtocol
    private let workingSetSignalRepo: any FileProviderWorkingSetSignalRepositoryProtocol
    private let signalDelay: Duration

    public init(
        nodeRepo: any NodeRepositoryProtocol,
        snapshotRepo: any FileProviderSnapshotRepositoryProtocol,
        changeQueueRepo: any FileProviderChangeQueueRepositoryProtocol,
        workingSetSignalRepo: any FileProviderWorkingSetSignalRepositoryProtocol,
        signalDelay: Duration = .seconds(1)
    ) {
        self.nodeRepo = nodeRepo
        self.snapshotRepo = snapshotRepo
        self.changeQueueRepo = changeQueueRepo
        self.workingSetSignalRepo = workingSetSignalRepo
        self.signalDelay = signalDelay
    }

    public func queueNodeUpdates() async throws {
        let queuedUpdates = nodeRepo.nodeUpdates
            .map { try await queueChanges(of: $0) }
            .filter { $0 }
        for try await _ in queuedUpdates.debounce(for: signalDelay) {
            try await workingSetSignalRepo.signalWorkingSet()
        }
    }

    // MARK: - Private

    /// - Returns: Whether any node was queued.
    private func queueChanges(of nodes: [NodeEntity]) async throws -> Bool {
        let snapshotContainers = Set(try await snapshotRepo.containerIdentifiers())
        let changes = nodes.compactMap { node -> FileProviderChangeEntity? in
            guard let parentIdentifier = parentIdentifier(of: node) else {
                return nil
            }
            // A moved node may still be shown in the folder it left, which the SDK does not tell, and the system keeps
            // what was moved to the trash without enumerating it. Any other node is only shown when the system has
            // enumerated its parent.
            guard node.changeTypes.contains(.parent) || parentIdentifier == .trashContainer
                    || snapshotContainers.contains(parentIdentifier) else {
                return nil
            }
            return FileProviderChangeEntity(identifier: NSFileProviderItemIdentifier(node.base64Handle), folderIdentifier: parentIdentifier)
        }
        guard !changes.isEmpty else {
            return false
        }
        try await changeQueueRepo.append(changes)
        return true
    }

    /// `nil` when the parent is no longer in the node tree.
    private func parentIdentifier(of node: NodeEntity) -> NSFileProviderItemIdentifier? {
        if let rootNode = nodeRepo.rootNode(), node.parentHandle == rootNode.handle {
            return .rootContainer
        }
        if let rubbishNode = nodeRepo.rubbishNode(), node.parentHandle == rubbishNode.handle {
            return .trashContainer
        }
        return nodeRepo.nodeForHandle(node.parentHandle).map { NSFileProviderItemIdentifier($0.base64Handle) }
    }
}
