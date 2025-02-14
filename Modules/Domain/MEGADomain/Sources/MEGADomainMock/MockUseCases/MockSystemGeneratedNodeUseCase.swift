import Foundation
import MEGADomain

public final class MockSystemGeneratedNodeUseCase: SystemGeneratedNodeUseCaseProtocol {
    
    private let nodesForLocation: [SystemGeneratedFolderLocationEntity: NodeEntity]
    
    public init(
        nodesForLocation: [SystemGeneratedFolderLocationEntity: NodeEntity] = [:]
    ) {
        self.nodesForLocation = nodesForLocation
    }
    
    public func node(for location: SystemGeneratedFolderLocationEntity) async throws -> NodeEntity {
        guard let node = nodesForLocation[location] else {
            throw SystemGeneratedFolderLocationErrorEntity.nodeDoesNotExist(location: location)
        }
        return node
    }
}
