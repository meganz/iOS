import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

// MARK: - Protocol

protocol AudioNodeUpdatesUseCaseProtocol: Sendable {
    /// Queued nodes that have left the Cloud Drive, keyed by handle, each mapped to the file
    /// standing in for it, or `nil` when nothing replaced it. A file is replaced by the latest
    /// version when an upload over it turns it into an older version, or by the only other file of
    /// its name in the folder it left — how another client replaces a file it moves, copies or
    /// uploads one onto: the new one in, then the old one out. Only non-empty dictionaries are emitted
    ///
    /// - Parameter queuedFolders: the queued nodes, each mapped to the folder it was in when it was
    ///   queued, read once per update. A node not in it is never reported, and an update with none
    ///   in it is passed over without asking the SDK anything. The folder stands in for the one to
    ///   restore to, for a file moved to the Rubbish Bin before that is written, as some clients
    ///   do. Called off the main actor, so it must not wait on it
    func removedNodes(
        queuedFolders: @escaping @Sendable () -> [HandleEntity: HandleEntity]
    ) -> AnyAsyncSequence<[HandleEntity: NodeEntity?]>

    /// Nodes that have left the folder-link tree, keyed by handle, each mapped to the authorized
    /// node of the new upload that replaced it — `nil` when nothing replaced it, or the
    /// replacement can no longer be found, either way leaving it simply gone. One update is one
    /// batch, so replacements and deletions are seen together. Only non-empty batches are emitted
    var removedFolderLinkNodes: AnyAsyncSequence<[HandleEntity: (any PlayableNode)?]> { get }

    /// Cloud Drive nodes whose name has changed, carrying the new name. Only
    /// non-empty batches are emitted.
    var renamedNodes: AnyAsyncSequence<[NodeEntity]> { get }

    /// Folder-link nodes whose name has changed, as authorized nodes carrying the
    /// new name — authorized, like the ones the queue was built from, so they can
    /// stand in for them. Only non-empty batches are emitted.
    var renamedFolderLinkNodes: AnyAsyncSequence<[any PlayableNode]> { get }
}

// MARK: - Implementation

struct AudioNodeUpdatesUseCase: AudioNodeUpdatesUseCaseProtocol {
    private let nodeRepository: any NodeRepositoryProtocol
    private let nodeAttributeRepository: any NodeAttributeRepositoryProtocol
    private let folderLinkNodeRepository: any AudioFolderLinkNodeRepositoryProtocol

    init(
        nodeRepository: some NodeRepositoryProtocol = DependencyInjection.nodeRepository,
        nodeAttributeRepository: some NodeAttributeRepositoryProtocol = DependencyInjection.nodeAttributeRepository,
        folderLinkNodeRepository: some AudioFolderLinkNodeRepositoryProtocol = DependencyInjection.folderLinkNodeRepository
    ) {
        self.nodeRepository = nodeRepository
        self.nodeAttributeRepository = nodeAttributeRepository
        self.folderLinkNodeRepository = folderLinkNodeRepository
    }

    func removedNodes(
        queuedFolders: @escaping @Sendable () -> [HandleEntity: HandleEntity]
    ) -> AnyAsyncSequence<[HandleEntity: NodeEntity?]> {
        let repository = nodeRepository
        let attributeRepository = nodeAttributeRepository
        return nodeRepository.nodeUpdates
            .map { nodes in
                let queued = queuedFolders()
                // Only a queued node bears on the queue, so no other is worth asking the SDK about
                let isQueued = { (node: NodeEntity) in queued[node.handle] != nil }

                var removals: [HandleEntity: NodeEntity?] = [:]
                for node in nodes where isQueued(node) && Self.isAudioFile(node) {
                    guard let latest = Self.latestVersion(replacing: node, in: repository) else { continue }
                    removals.updateValue(latest, forKey: node.handle)
                }

                let deleted = nodes.filter { isQueued($0) && Self.isDeleted($0, in: attributeRepository) }
                let namesakes = await Self.namesakeReplacements(
                    for: deleted,
                    queuedFolders: queued,
                    repository: repository
                )
                for node in deleted {
                    // `updateValue`, as assigning `nil` through the subscript would drop the key
                    removals.updateValue(namesakes[node.handle], forKey: node.handle)
                }
                return removals
            }
            .filter { $0.isNotEmpty }
            .eraseToAnyAsyncSequence()
    }

    var removedFolderLinkNodes: AnyAsyncSequence<[HandleEntity: (any PlayableNode)?]> {
        let repository = folderLinkNodeRepository
        return nodeRepository.folderLinkNodeUpdates
            .map { nodes in
                let replacements = Self.folderLinkReplacements(in: nodes)
                var removals: [HandleEntity: (any PlayableNode)?] = [:]
                for node in nodes where node.changeTypes.contains(.removed) {
                    // `updateValue`, as assigning `nil` through the subscript would drop the key
                    removals.updateValue(
                        replacements[node.handle].flatMap { repository.authorizedNode(forHandle: $0) },
                        forKey: node.handle
                    )
                }
                return removals
            }
            .filter { $0.isNotEmpty }
            .eraseToAnyAsyncSequence()
    }

    var renamedNodes: AnyAsyncSequence<[NodeEntity]> {
        nodeRepository.nodeUpdates
            .map { nodes in nodes.filter { $0.changeTypes.contains(.name) } }
            .filter { $0.isNotEmpty }
            .eraseToAnyAsyncSequence()
    }

    var renamedFolderLinkNodes: AnyAsyncSequence<[any PlayableNode]> {
        let repository = folderLinkNodeRepository
        return nodeRepository.folderLinkNodeUpdates
            .map { nodes in
                nodes
                    .filter { $0.changeTypes.contains(.name) }
                    .compactMap { repository.authorizedNode(forHandle: $0.handle) }
            }
            .filter { $0.isNotEmpty }
            .eraseToAnyAsyncSequence()
    }

    /// The version now standing in for `node`, when the update is `node` becoming a
    /// version. Versions hang under the file that replaced them, so the latest one is the
    /// first file up the chain whose own parent is not a file — followed up rather than
    /// taken from the parent, in case more than one replacement arrived in one update.
    private static func latestVersion(
        replacing node: NodeEntity,
        in repository: any NodeRepositoryProtocol
    ) -> NodeEntity? {
        guard node.changeTypes.contains(.parent),
              var latest = repository.nodeForHandle(node.parentHandle),
              latest.isFile else { return nil }

        var visited: Set<HandleEntity> = [node.handle, latest.handle]
        while let parent = repository.nodeForHandle(latest.parentHandle),
              parent.isFile,
              visited.insert(parent.handle).inserted {
            latest = parent
        }
        return latest
    }

    /// Finds, for each deleted audio file, the file that replaced it: another client replaces a
    /// file by putting one of the same name into its folder, then deleting the old one.
    ///
    /// A deleted file is paired with a file when all of these hold:
    /// - it is an audio file, and the folder it left is known and not in the Rubbish Bin
    /// - it is the only file in `deleted` of its name that left that folder
    /// - that folder now holds exactly one other file of its name, which is not in `deleted`
    ///
    /// - Parameters:
    ///   - deleted: the queued files that have left the Cloud Drive, either deleted for good or
    ///     moved to the Rubbish Bin
    ///   - queuedFolders: the queued nodes, each mapped to the folder it was in when queued
    /// - Returns: the replacing file, keyed by the deleted file's handle; a deleted file with no
    ///   replacement is left out
    private static func namesakeReplacements(
        for deleted: [NodeEntity],
        queuedFolders: [HandleEntity: HandleEntity],
        repository: any NodeRepositoryProtocol
    ) async -> [HandleEntity: NodeEntity] {
        let deletedHandles = Set(deleted.map(\.handle))
        let byFolder = Dictionary(grouping: deleted.filter(isAudioFile)) {
            formerFolderHandle($0, lastKnownFolder: queuedFolders[$0.handle])
        }
        var pairs: [HandleEntity: NodeEntity] = [:]
        for (folderHandle, files) in byFolder {
            // A folder in the Rubbish Bin took its files with it
            guard folderHandle != .invalid,
                  let folder = repository.nodeForHandle(folderHandle), folder.isFolder,
                  !repository.isInRubbishBin(node: folder),
                  let children = await repository.asyncChildren(of: folder, sortOrder: .none) else { continue }

            let residents = Dictionary(
                grouping: children.toNodeEntities().filter { $0.isFile && !deletedHandles.contains($0.handle) },
                by: \.name
            )
            // More than one on either side leaves it open which replaced which
            for (name, oldFiles) in Dictionary(grouping: files, by: \.name) {
                guard let old = oldFiles.only, let new = residents[name]?.only else { continue }
                pairs[old.handle] = new
            }
        }
        return pairs
    }

    /// The folder a deleted node left: one deleted for good is reported with the folder it had,
    /// while one moved to the Rubbish Bin keeps it as the folder to restore to — once that is
    /// written, which some clients only do after the move, so until then it falls back to the
    /// folder the node was last known to be in
    ///
    /// - Parameter lastKnownFolder: the folder the node was last known to be in, if known
    private static func formerFolderHandle(
        _ node: NodeEntity,
        lastKnownFolder: HandleEntity?
    ) -> HandleEntity {
        if node.changeTypes.contains(.removed) { return node.parentHandle }
        if node.restoreParentHandle != .invalid { return node.restoreParentHandle }
        return lastKnownFolder ?? .invalid
    }

    /// An audio file leaving a folder while exactly one file with its name arrives there, in the
    /// same update — old handle to new handle. The removed node is reported with the name
    /// and folder it had when it left.
    private static func folderLinkReplacements(in nodes: [NodeEntity]) -> [HandleEntity: HandleEntity] {
        let key = { (node: NodeEntity) in "\(node.parentHandle)/\(node.name)" }
        let leaving = Dictionary(grouping: nodes.filter { $0.changeTypes.contains(.removed) && isAudioFile($0) }, by: key)
        let arriving = Dictionary(grouping: nodes.filter { $0.changeTypes.contains(.new) && isAudioFile($0) }, by: key)
        return leaving.reduce(into: [:]) { pairs, entry in
            guard let old = entry.value.only, let new = arriving[entry.key]?.only else { return }
            pairs[old.handle] = new.handle
        }
    }

    /// Only an audio file can back a track, so nothing else is worth a lookup. Checked by
    /// the name the update carries — the one a removed node had when it left.
    private static func isAudioFile(_ node: NodeEntity) -> Bool {
        node.isFile && node.name.fileExtensionGroup.isAudio
    }

    private static func isDeleted(
        _ node: NodeEntity,
        in repository: any NodeAttributeRepositoryProtocol
    ) -> Bool {
        // A permanent delete is reported as `.removed`
        if node.changeTypes.contains(.removed) { return true }
        // A move only counts once it has landed in the Rubbish Bin
        guard node.changeTypes.contains(.parent) else { return false }
        return repository.isInRubbishBin(node: node)
    }
}

private extension Array {
    var only: Element? { count == 1 ? first : nil }
}
