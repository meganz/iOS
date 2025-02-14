import Foundation

/// Provides access to  system generated/managed nodes.
public protocol SystemGeneratedNodeUseCaseProtocol: Sendable {
    
    /// Retrieve the system generated NodeEntity for the provided location.
    /// - Parameter location: location type used to define which system managed node to fetch
    /// - Returns: NodeEntity for the provided system managed location
    /// - Throws: SystemGeneratedFolderLocationErrorEntity.nodeDoesNotExist if the node does not exist for the given location.
    func node(for location: SystemGeneratedFolderLocationEntity) async throws -> NodeEntity
}

public struct SystemGeneratedNodeUseCase<T: SystemGeneratedNodeRepositoryProtocol>: SystemGeneratedNodeUseCaseProtocol {
    
    private let systemGeneratedNodeRepository: T
    
    public init(systemGeneratedNodeRepository: T) {
        self.systemGeneratedNodeRepository = systemGeneratedNodeRepository
    }
    
    public func node(for location: SystemGeneratedFolderLocationEntity) async throws -> NodeEntity {
        try await systemGeneratedNodeRepository.node(for: location)
    }
}
