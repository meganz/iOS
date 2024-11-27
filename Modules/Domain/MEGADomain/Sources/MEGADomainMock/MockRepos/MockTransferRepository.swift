import Foundation
import MEGADomain

public struct MockTransferRepository: TransferRepositoryProtocol {
    
    public static var newRepo: MockTransferRepository {
        MockTransferRepository()
    }
    
    public func uploadFile(at fileUrl: URL, to parent: NodeEntity, startHandler: ((TransferEntity) -> Void)? = nil, progressHandler: ((TransferEntity) -> Void)? = nil) async throws -> TransferEntity {
        TransferEntity(type: .upload, path: fileUrl.path, parentHandle: parent.handle)
    }
    
    public func download(
        node: NodeEntity,
        to localUrl: URL,
        collisionResolution: CollisionResolutionEntity = .renameNewWithSuffix,
        startHandler: ((TransferEntity) -> Void)? = nil,
        progressHandler: ((TransferEntity) -> Void)? = nil
    ) async throws -> TransferEntity {
        TransferEntity(type: .download, path: localUrl.path, nodeHandle: node.handle)
    }
}
