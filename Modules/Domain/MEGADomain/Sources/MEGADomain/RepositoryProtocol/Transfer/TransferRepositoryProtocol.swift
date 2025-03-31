import Foundation
import MEGASwift

public protocol TransferRepositoryProtocol: RepositoryProtocol, Sendable {
    var completedTransferUpdates: AnyAsyncSequence<TransferEntity> { get }
    
    func download(
        node: NodeEntity,
        to localUrl: URL,
        collisionResolution: CollisionResolutionEntity,
        startHandler: ((TransferEntity) -> Void)?,
        progressHandler: ((TransferEntity) -> Void)?
    ) async throws -> TransferEntity
    
    func uploadFile(at fileUrl: URL, to parent: NodeEntity, startHandler: ((TransferEntity) -> Void)?, progressHandler: ((TransferEntity) -> Void)?) async throws -> TransferEntity
}
