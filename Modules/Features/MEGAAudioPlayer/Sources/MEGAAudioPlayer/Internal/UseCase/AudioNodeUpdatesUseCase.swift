import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

// MARK: - Protocol

protocol AudioNodeUpdatesUseCaseProtocol: Sendable {
    /// Handles of the nodes that have left the Cloud Drive. Only non-empty batches
    /// are emitted; one batch can carry several handles, since deleting a
    /// multi-selection is reported as a single update.
    var deletedNodeHandles: AnyAsyncSequence<Set<HandleEntity>> { get }
}

// MARK: - Implementation

struct AudioNodeUpdatesUseCase: AudioNodeUpdatesUseCaseProtocol {
    private let nodeUpdatesProvider: any NodeUpdatesProviderProtocol
    private let nodeAttributeRepository: any NodeAttributeRepositoryProtocol

    init(
        nodeUpdatesProvider: some NodeUpdatesProviderProtocol = DependencyInjection.nodeUpdatesProvider,
        nodeAttributeRepository: some NodeAttributeRepositoryProtocol = DependencyInjection.nodeAttributeRepository
    ) {
        self.nodeUpdatesProvider = nodeUpdatesProvider
        self.nodeAttributeRepository = nodeAttributeRepository
    }

    var deletedNodeHandles: AnyAsyncSequence<Set<HandleEntity>> {
        let repository = nodeAttributeRepository
        return nodeUpdatesProvider
            .nodeUpdates
            .map { nodes in
                Set(
                    nodes
                        .filter { Self.isDeleted($0, in: repository) }
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
