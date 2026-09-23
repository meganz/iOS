import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

// MARK: - Protocol

protocol AudioNodeUpdatesUseCaseProtocol: Sendable {
    /// Handles of the nodes that have left the Cloud Drive. Only non-empty batches
    /// are emitted; one batch can carry several handles, since deleting a
    /// multi-selection is reported as a single update.
    var deletedNodeHandles: AnyAsyncSequence<Set<HandleEntity>> { get }

    /// Handles of the nodes that have left the folder-link tree. Reported by the
    /// folder-link SDK instance, which is the only one that sees that tree, and
    /// therefore only meaningful while a folder link is what is playing.
    var deletedFolderLinkNodeHandles: AnyAsyncSequence<Set<HandleEntity>> { get }
}

// MARK: - Implementation

struct AudioNodeUpdatesUseCase: AudioNodeUpdatesUseCaseProtocol {
    private let nodeRepository: any NodeRepositoryProtocol
    private let nodeAttributeRepository: any NodeAttributeRepositoryProtocol

    init(
        nodeRepository: some NodeRepositoryProtocol = DependencyInjection.nodeRepository,
        nodeAttributeRepository: some NodeAttributeRepositoryProtocol = DependencyInjection.nodeAttributeRepository
    ) {
        self.nodeRepository = nodeRepository
        self.nodeAttributeRepository = nodeAttributeRepository
    }

    var deletedNodeHandles: AnyAsyncSequence<Set<HandleEntity>> {
        let repository = nodeAttributeRepository
        return Self.deletedHandles(in: nodeRepository.nodeUpdates) { node in
            Self.isDeleted(node, in: repository)
        }
    }

    var deletedFolderLinkNodeHandles: AnyAsyncSequence<Set<HandleEntity>> {
        Self.deletedHandles(in: nodeRepository.folderLinkNodeUpdates) { node in
            node.changeTypes.contains(.removed)
        }
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
