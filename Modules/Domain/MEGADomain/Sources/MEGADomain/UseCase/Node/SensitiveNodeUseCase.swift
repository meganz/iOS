import AsyncAlgorithms
import MEGASwift

public protocol SensitiveNodeUseCaseProtocol: Sendable {
    /// Ascertain if the node's ancestor is marked as sensitive
    ///  - Parameters: node - the node to check
    ///  - Returns: true if the node's ancestor is marked as sensitive
    ///  - Throws: `NodeError.nodeNotFound` if the parent node cant be found
    func isInheritingSensitivity(node: NodeEntity) async throws -> Bool
    /// Ascertain if the node's ancestor is marked as sensitive
    ///  - Parameters: node - the node to check
    ///  - Returns: true if the node's ancestor is marked as sensitive
    ///  - Throws: `NodeError.nodeNotFound` if the parent node cant be found
    /// - Important: This could possibly block the calling thread, make sure not to call it on main thread.
    func isInheritingSensitivity(node: NodeEntity) throws -> Bool
    /// On a folder sensitivity change it will recalculate the inherited sensitivity of the ancestor of the node.
    /// - Parameter node: The node check for inherited sensitivity changes
    /// - Returns: An `AnyAsyncThrowingSequence<Bool>` indicating inherited sensitivity changes
    func monitorInheritedSensitivity(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error>
    /// On node update it will yield the sensitivity changes of the node
    /// - Parameter node: The node check for sensitive change types
    /// - Returns: An `AnyAsyncSequence<Bool>` indicating node sensitivity changes
    func sensitivityChanges(for node: NodeEntity) -> AnyAsyncSequence<Bool>
    /// Merges sensitivity changes due to node inheritance and the direct sensitivity changes of the node itself.
    ///
    /// This method combines two streams:
    /// - `monitorInheritedSensitivity(for:)`: Monitors sensitivity changes that are inherited from parent nodes.
    /// - `sensitivityChanges(for:)`: Monitors direct sensitivity changes of the node itself.
    ///
    /// The resulting stream emits `Bool` values indicating sensitivity changes, where `true` means the node is sensitive
    /// and `false` means it is not. This method is useful for tracking both inherited and direct sensitivity changes
    /// in a unified way.
    ///
    /// - Parameter node: The `NodeEntity` for which to monitor sensitivity changes.
    /// - Returns: An `AnyAsyncThrowingSequence<Bool, any Error>` that emits sensitivity change events for the specified node.
    func mergeInheritedAndDirectSensitivityChanges(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error>
}

public struct SensitiveNodeUseCase<T: NodeRepositoryProtocol>: SensitiveNodeUseCaseProtocol {
    
    private let nodeRepository: T
    
    public init(nodeRepository: T) {
        self.nodeRepository = nodeRepository
    }
    
    public func isInheritingSensitivity(node: NodeEntity) async throws -> Bool {
        try await nodeRepository.isInheritingSensitivity(node: node)
    }
    
    public func isInheritingSensitivity(node: NodeEntity) throws -> Bool {
        try nodeRepository.isInheritingSensitivity(node: node)
    }
    
    public func monitorInheritedSensitivity(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        nodeRepository.nodeUpdates
            .filter { $0.contains { $0.isFolder && $0.changeTypes.contains(.sensitive)} }
            .map { _ in
                try await nodeRepository.isInheritingSensitivity(node: node)
            }
            .removeDuplicates()
            .eraseToAnyAsyncThrowingSequence()
    }
    
    public func sensitivityChanges(for node: NodeEntity) -> AnyAsyncSequence<Bool> {
        nodeRepository.nodeUpdates
            .compactMap {
                $0.first(where: {
                    $0.handle == node.handle && $0.changeTypes.contains(.sensitive)
                })?.isMarkedSensitive
            }
            .eraseToAnyAsyncSequence()
    }
    
    public func mergeInheritedAndDirectSensitivityChanges(
        for node: NodeEntity
    ) -> AnyAsyncThrowingSequence<Bool, any Error> {
        AsyncAlgorithms.merge(
            sensitivityChanges(for: node),
            monitorInheritedSensitivity(for: node)
        )
        .eraseToAnyAsyncThrowingSequence()
    }
}
