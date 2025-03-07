import AsyncAlgorithms
import Combine
import Foundation
import MEGASwift

public protocol SensitiveNodeUseCaseProtocol: Sendable {
    
    /// Determine is the current logged in user has a valid account type, that gives them access to use the Hidden Files features
    /// This is determined by what account type they have such pro (I, II, III), flexi, business, lowTierplans and etc
    /// - Returns: Return true, if the active user has the correct account type to use hidden files feature. Else false.
    func isAccessible() -> Bool

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
    /// On node update it will yield if folder sensitivity has changed
    /// - Returns: An `AnyAsyncSequence<Void>` indicating folder sensitivity changed
    func folderSensitivityChanged() -> AnyAsyncSequence<Void>
    
    /// Return the cached inherited sensitivity state for a given node.
    func cachedInheritedSensitivity(for nodeHandle: HandleEntity) -> Bool?
}

public struct SensitiveNodeUseCase<T: NodeRepositoryProtocol, U: AccountUseCaseProtocol>: SensitiveNodeUseCaseProtocol {
    
    private let nodeRepository: T
    private let accountUseCase: U
    
    public init(
        nodeRepository: T,
        accountUseCase: U
    ) {
        self.nodeRepository = nodeRepository
        self.accountUseCase = accountUseCase
    }
    
    public func isAccessible() -> Bool {
        switch accountUseCase.currentAccountDetails?.proLevel {
        case .lite, .proI, .proII, .proIII, .business, .proFlexi:
            accountUseCase.hasValidProOrUnexpiredBusinessAccount()
        case .starter, .basic, .essential:
            true
        case nil, .free, .feature:
            false
        }
    }
    
    public func isInheritingSensitivity(node: NodeEntity) async throws -> Bool {
        guard isAccessible() else { return false }
        
        let isSensitive = try await nodeRepository.isInheritingSensitivity(node: node)
        
        NodeInheritedSensitivityCache.shared.updateCachedInheritedSensitivity(isSensitive, for: node.handle)
        
        return isSensitive
    }
    
    public func isInheritingSensitivity(node: NodeEntity) throws -> Bool {
        guard isAccessible() else { return false }
        
        return try nodeRepository.isInheritingSensitivity(node: node)
    }
    
    public func monitorInheritedSensitivity(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        guard isAccessible() else {
            return EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence()
        }
        return nodeRepository.nodeUpdates
            .filter { $0.contains { $0.isFolder && $0.changeTypes.contains(.sensitive)} }
            .map { _ in
                let isSensitive = try await nodeRepository.isInheritingSensitivity(node: node)
                NodeInheritedSensitivityCache.shared.updateCachedInheritedSensitivity(isSensitive, for: node.handle)
                return isSensitive
            }
            .removeDuplicates()
            .eraseToAnyAsyncThrowingSequence()
    }
    
    public func sensitivityChanges(for node: NodeEntity) -> AnyAsyncSequence<Bool> {
        guard isAccessible() else {
            return EmptyAsyncSequence().eraseToAnyAsyncSequence()
        }
        return nodeRepository.nodeUpdates
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
        guard isAccessible() else {
            return EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence()
        }
        return AsyncAlgorithms.merge(
            sensitivityChanges(for: node),
            monitorInheritedSensitivity(for: node)
        )
        .eraseToAnyAsyncThrowingSequence()
    }
    
    public func folderSensitivityChanged() -> AnyAsyncSequence<Void> {
        guard isAccessible() else {
            return EmptyAsyncSequence().eraseToAnyAsyncSequence()
        }
        return nodeRepository
            .nodeUpdates
            .compactMap {
                $0.first(where: { $0.isFolder && $0.changeTypes.contains(.sensitive) })
                    .map({ _ in () })
            }
            .eraseToAnyAsyncSequence()
    }
    
    public func cachedInheritedSensitivity(for nodeHandle: HandleEntity) -> Bool? {
        NodeInheritedSensitivityCache.shared.cachedInheritedSensitivity(for: nodeHandle)
    }
}

/// This is a workaround to fix CC-8509.
/// Maintain the last updated inherited sensitivity state.
final class NodeInheritedSensitivityCache: @unchecked Sendable {
    @Atomic private var inheritedSensitivityState: [HandleEntity: Bool] = [:]
    private var cancellable: AnyCancellable? // init within shared singleton, hence no Atomic needed
    
    static let shared = NodeInheritedSensitivityCache()
    
    init() {
        cancellable = NotificationCenter
            .default
            .publisher(for: .accountDidLogout)
            .sink { [weak self] _ in
                self?.clearInheritedSensitivityState()
            }
    }
    
    func cachedInheritedSensitivity(for nodeHandle: HandleEntity) -> Bool? {
        inheritedSensitivityState[nodeHandle]
    }
    
    func updateCachedInheritedSensitivity(_ isSensitive: Bool, for nodeHandle: HandleEntity) {
        $inheritedSensitivityState.mutate { $0[nodeHandle] = isSensitive }
    }
    
    private func clearInheritedSensitivityState() {
        $inheritedSensitivityState.mutate { $0.removeAll() }
    }
}
