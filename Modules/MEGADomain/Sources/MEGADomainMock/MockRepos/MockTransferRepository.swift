import Foundation
import MEGADomain

public struct MockTransferRepository: TransferRepositoryProtocol {
    
    public static var newRepo: MockTransferRepository {
        MockTransferRepository()
    }
    
    public func download(node: NodeEntity, to localUrl: URL) async throws -> TransferEntity {
        TransferEntity(type: .download, path: localUrl.path, nodeHandle: node.handle)
    }
    
    public func uploadFile(at fileUrl: URL, to parent: NodeEntity) async throws -> TransferEntity {
        TransferEntity(type: .upload, path: fileUrl.path, parentHandle: parent.handle)
    }
}
