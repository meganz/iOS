struct PhotoLibraryRepository: PhotoLibraryRepositoryProtocol {
    static var newRepo: PhotoLibraryRepository {
        PhotoLibraryRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    func nodes(inParent parentNode: MEGANode?) -> [MEGANode] {
        guard let parentNode = parentNode else {
            return []
        }

        let nodeList = sdk.children(
            forParent: parentNode,
            order: MEGASortOrderType.modificationDesc.rawValue
        )
        
        return nodeList.toNodeArray().filter {
            $0.name?.mnz_isVisualMediaPathExtension ?? false
        }
    }
    
    func videoNodes(inParent parentNode: MEGANode?) -> [MEGANode] {
        guard let parentNode = parentNode else {
            return []
        }

        let nodeList = sdk.children(
            forParent: parentNode,
            order: MEGASortOrderType.modificationDesc.rawValue
        )
        
        return nodeList.toNodeArray().filter {
            $0.name?.mnz_isVideoPathExtension ?? false
        }
    }
    
    func node(in source: PhotoSourceEntity) async throws -> MEGANode? {
        switch source {
        case .camera:
            return try await cameraUploadNode()
        case .media:
            return try await mediaUploadNode()
        }
    }
    
    private func cameraUploadNode() async throws -> MEGANode? {
        try await withCheckedThrowingContinuation { continuation in
            CameraUploadNodeAccess.shared.loadNode { node, error in
                guard Task.isCancelled == false
                else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                if let node = node {
                    continuation.resume(returning: node)
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
    
    private func mediaUploadNode() async throws -> MEGANode? {
        try await withCheckedThrowingContinuation { continuation in
            MediaUploadNodeAccess.shared.loadNode { node, error in
                guard Task.isCancelled == false
                else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                if let node = node {
                    continuation.resume(returning: node)
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
