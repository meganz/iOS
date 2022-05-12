import Foundation

protocol AlbumRepositoryProtocol {
    func loadAlbums() async throws -> [NodeEntity]
}

struct AlbumRepository: AlbumRepositoryProtocol {
    
    // load Favourite album only for now
    func loadAlbums() async throws -> [NodeEntity] {
        try await withCheckedThrowingContinuation { continuation in
            CameraUploadNodeAccess.shared.loadNode { (node, error) in
                guard Task.isCancelled == false else { continuation.resume(throwing: CancellationError()); return }
                
                if let error = error {
                    MEGALogWarning("Couldn't load CU: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                if let node = node?.toNodeEntity() {
                    continuation.resume(returning: [node])
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
}
