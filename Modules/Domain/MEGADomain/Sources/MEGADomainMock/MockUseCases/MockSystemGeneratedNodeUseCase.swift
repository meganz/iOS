import Foundation
import MEGADomain

public final class MockSystemGeneratedNodeUseCase: SystemGeneratedNodeUseCaseProtocol {
    
    private let nodesForLocation: [SystemGeneratedFolderLocationEntity: NodeEntity]
    private let containsSystemGeneratedNodeError: (any Error)?
    
    public init(
        nodesForLocation: [SystemGeneratedFolderLocationEntity: NodeEntity] = [:],
        containsSystemGeneratedNodeError: (any Error)? = nil) {
        self.nodesForLocation = nodesForLocation
        self.containsSystemGeneratedNodeError = containsSystemGeneratedNodeError
    }
    
    public func node(for location: SystemGeneratedFolderLocationEntity) async throws -> NodeEntity {
        guard let node = nodesForLocation[location] else {
            throw SystemGeneratedFolderLocationErrorEntity.nodeDoesNotExist(location: location)
        }
        return node
    }
    
    public func containsSystemGeneratedNode(nodes: [NodeEntity]) async throws -> Bool {
        if let containsSystemGeneratedNodeError {
            throw containsSystemGeneratedNodeError
        } else {
            nodes.contains { node in
                nodesForLocation.values.contains(where: { node.handle == $0.handle })
            }
        }
    }
}
