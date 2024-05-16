import Foundation

/// Protocol that defines methods to fetch the system generated/managed nodes.
public protocol SystemGeneratedNodeRepositoryProtocol: Sendable {
    
    /// Retrieve the system generated NodeEntity for the provided location.
    /// - Parameter location: location type used to define which system managed node to fetch
    /// - Returns: NodeEntity for the provided system managed location
    /// - Throws: SystemGeneratedFolderLocationErrorEntity.nodeDoesNotExist if the node does not exist for the given location.
    func node(for location: SystemGeneratedFolderLocationEntity) async throws -> NodeEntity
}
