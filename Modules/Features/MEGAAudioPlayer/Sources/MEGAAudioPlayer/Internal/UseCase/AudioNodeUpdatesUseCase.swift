import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

// MARK: - Protocol

protocol AudioNodeUpdatesUseCaseProtocol: Sendable {
    /// Handles of the nodes that have left the Cloud Drive. Only non-empty batches
    /// are emitted; one batch can carry several handles, since deleting a
    /// multi-selection is reported as a single update.
    var deletedNodeHandles: AnyAsyncSequence<Set<HandleEntity>> { get }

    /// Cloud Drive files replaced by a new version, keyed by the replaced node's handle,
    /// each mapped to the latest version. Only non-empty batches are emitted
    var replacedNodes: AnyAsyncSequence<[HandleEntity: NodeEntity]> { get }

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

    var deletedNodeHandles: AnyAsyncSequence<Set<HandleEntity>> {
        let repository = nodeAttributeRepository
        return Self.deletedHandles(in: nodeRepository.nodeUpdates) { node in
            Self.isDeleted(node, in: repository)
        }
    }

    var replacedNodes: AnyAsyncSequence<[HandleEntity: NodeEntity]> {
        let repository = nodeRepository
        return nodeRepository.nodeUpdates
            .map { nodes in
                var replacements: [HandleEntity: NodeEntity] = [:]
                for node in nodes {
                    guard let latest = Self.latestVersion(replacing: node, in: repository) else { continue }
                    replacements[node.handle] = latest
                }
                return replacements
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

    private static func deletedHandles(
        in nodeUpdates: AnyAsyncSequence<[NodeEntity]>,
        isDeleted: @escaping @Sendable (NodeEntity) -> Bool
    ) -> AnyAsyncSequence<Set<HandleEntity>> {
        nodeUpdates
            .map { nodes in
                Set(
                    nodes
                        .filter(isDeleted)
                        .map(\.handle)
                )
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

    /// A file leaving a folder while exactly one file with its name arrives there, in the
    /// same update — old handle to new handle. The removed node is reported with the name
    /// and folder it had when it left.
    private static func folderLinkReplacements(in nodes: [NodeEntity]) -> [HandleEntity: HandleEntity] {
        let key = { (node: NodeEntity) in "\(node.parentHandle)/\(node.name)" }
        let leaving = Dictionary(grouping: nodes.filter { $0.changeTypes.contains(.removed) && $0.isFile }, by: key)
        let arriving = Dictionary(grouping: nodes.filter { $0.changeTypes.contains(.new) && $0.isFile }, by: key)
        return leaving.reduce(into: [:]) { pairs, entry in
            guard let old = entry.value.only, let new = arriving[entry.key]?.only else { return }
            pairs[old.handle] = new.handle
        }
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
