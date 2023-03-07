import Foundation

public protocol TransferRepositoryProtocol: RepositoryProtocol {
    func download(node: NodeEntity, to localUrl: URL, startHandler: ((TransferEntity) -> Void)?, progressHandler: ((TransferEntity) -> Void)?) async throws -> TransferEntity
    func uploadFile(at fileUrl: URL, to parent: NodeEntity, startHandler: ((TransferEntity) -> Void)?, progressHandler: ((TransferEntity) -> Void)?) async throws -> TransferEntity
}
