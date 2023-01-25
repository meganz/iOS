import MEGADomain

struct PhotoLibraryRepository: PhotoLibraryRepositoryProtocol {
    static var newRepo: PhotoLibraryRepository {
        PhotoLibraryRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func visualMediaNodes(inParent parentNode: NodeEntity?) -> [NodeEntity] {
        guard let parentNode = parentNode?.toMEGANode(in: sdk) else {
            return []
        }
        
        let nodeList = sdk.children(
            forParent: parentNode,
            order: MEGASortOrderType.modificationDesc.rawValue
        )
        
        return nodeList.toNodeArray().filter {
            $0.name?.mnz_isVisualMediaPathExtension ?? false
        }.toNodeEntities()
    }
    
    func videoNodes(inParent parentNode: NodeEntity?) -> [NodeEntity] {
        guard let parentNode = parentNode?.toMEGANode(in: sdk) else {
            return []
        }
        
        let nodeList = sdk.children(
            forParent: parentNode,
            order: MEGASortOrderType.modificationDesc.rawValue
        )
        
        return nodeList.toNodeArray().filter {
            $0.name?.mnz_isVideoPathExtension ?? false
        }.toNodeEntities()
    }
    
    func photoSourceNode(for source: PhotoSourceEntity) async throws -> NodeEntity? {
        switch source {
        case .camera:
            return try await cameraUploadNode()
        case .media:
            return try await mediaUploadNode()
        }
    }
    
    private func cameraUploadNode() async throws -> NodeEntity? {
        try await withCheckedThrowingContinuation { continuation in
            CameraUploadNodeAccess.shared.loadNode { node, error in
                guard Task.isCancelled == false
                else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                if let node {
                    continuation.resume(returning: node.toNodeEntity())
                }
                else if let error = error {
                    MEGALogWarning("Couldn't load CU: \(error)")
                    continuation.resume(throwing: PhotoLibraryErrorEntity.cameraUploadNodeDoesNotExist)
                }
                else {
                    continuation.resume(throwing: PhotoLibraryErrorEntity.cameraUploadNodeDoesNotExist)
                }
            }
        }
    }
    
    private func mediaUploadNode() async throws -> NodeEntity? {
        try await withCheckedThrowingContinuation { continuation in
            MediaUploadNodeAccess.shared.loadNode { node, error in
                guard Task.isCancelled == false
                else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                if let node {
                    continuation.resume(returning: node.toNodeEntity())
                }
                else if let error = error {
                    MEGALogWarning("Couldn't load MU: \(error)")
                    continuation.resume(throwing: PhotoLibraryErrorEntity.mediaUploadNodeDoesNotExist)
                }
                else {
                    continuation.resume(throwing: PhotoLibraryErrorEntity.mediaUploadNodeDoesNotExist)
                }
            }
        }
    }
}
