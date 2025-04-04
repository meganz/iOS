import MEGADomain
import MEGASdk
import MEGASwift

public struct SystemGeneratedNodeRepository: SystemGeneratedNodeRepositoryProtocol {
    
    private let nodeAccess: [SystemGeneratedFolderLocationEntity: any NodeAccessProtocol]
    
    public init(cameraUploadNodeAccess: some NodeAccessProtocol,
                mediaUploadNodeAccess: some NodeAccessProtocol,
                myChatFilesFolderNodeAccess: some NodeAccessProtocol) {
        
        nodeAccess = [
            .cameraUpload: cameraUploadNodeAccess,
            .mediaUpload: mediaUploadNodeAccess,
            .myChatFiles: myChatFilesFolderNodeAccess
        ]
    }
    
    public func node(for location: SystemGeneratedFolderLocationEntity) async throws -> NodeEntity {
        
        guard let nodeAccess = nodeAccess[location] else {
            throw SystemGeneratedFolderLocationErrorEntity.nodeAccessHasNotBeenProvided(location: location)
        }
        return try await fetchNode(from: nodeAccess, location: location)
    }
    
    private func fetchNode(from access: some NodeAccessProtocol, location: SystemGeneratedFolderLocationEntity) async throws -> NodeEntity {
        try await withAsyncThrowingValue { continuation in
            access.loadNode { node, error in                
                if let node {
                    continuation(.success(node.toNodeEntity()))
                } else if let error = error {
                    let message = "[iOS] [SystemGeneratedNodeRepository] Couldn't load node for \(location): \(error)"
                    MEGASdk.log(with: .error, message: message, filename: #file, line: #line)
                    continuation(.failure(SystemGeneratedFolderLocationErrorEntity.nodeDoesNotExist(location: location)))
                } else {
                    continuation(.failure(SystemGeneratedFolderLocationErrorEntity.nodeDoesNotExist(location: location)))
                }
            }
        }
    }
}
