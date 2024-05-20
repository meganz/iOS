import Foundation

/// Provides access to  system generated/managed nodes.
public protocol SystemGeneratedNodeUseCaseProtocol: Sendable {
    
    /// Retrieve the system generated NodeEntity for the provided location.
    /// - Parameter location: location type used to define which system managed node to fetch
    /// - Returns: NodeEntity for the provided system managed location
    /// - Throws: SystemGeneratedFolderLocationErrorEntity.nodeDoesNotExist if the node does not exist for the given location.
    func node(for location: SystemGeneratedFolderLocationEntity) async throws -> NodeEntity
    
    func containsSystemGeneratedNode(nodes: [NodeEntity]) async throws -> Bool
}

public struct SystemGeneratedNodeUseCase<T: SystemGeneratedNodeRepositoryProtocol>: SystemGeneratedNodeUseCaseProtocol {
    
    private let systemGeneratedNodeRepository: T
    
    public init(systemGeneratedNodeRepository: T) {
        self.systemGeneratedNodeRepository = systemGeneratedNodeRepository
    }
    
    public func node(for location: SystemGeneratedFolderLocationEntity) async throws -> NodeEntity {
        try await systemGeneratedNodeRepository.node(for: location)
    }
        
    public func containsSystemGeneratedNode(nodes: [NodeEntity]) async throws -> Bool {
        try await withThrowingTaskGroup(of: Bool.self) { taskGroup in
            for location in SystemGeneratedFolderLocationEntity.allCases {
                guard taskGroup.addTaskUnlessCancelled(operation: { try await isSystemNode(location: location, includedIn: nodes) }) else {
                    break
                }
            }
            return try await taskGroup.contains(true)
        }
    }
}

extension SystemGeneratedNodeUseCase {
    private func isSystemNode(location: SystemGeneratedFolderLocationEntity, includedIn nodes: [NodeEntity]) async throws -> Bool {
        do {
            let systemNode = try await node(for: location)
            return nodes.contains { $0.handle == systemNode.handle }
        } catch SystemGeneratedFolderLocationErrorEntity.nodeDoesNotExist {
            return false
        }
    }
}
