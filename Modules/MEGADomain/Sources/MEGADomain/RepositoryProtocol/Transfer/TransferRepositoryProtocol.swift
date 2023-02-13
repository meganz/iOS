import Foundation

public protocol TransferRepositoryProtocol: RepositoryProtocol {
    func download(node: NodeEntity, to localUrl: URL) async throws -> TransferEntity
    func uploadFile(at fileUrl: URL, to parent: NodeEntity) async throws -> TransferEntity
}
