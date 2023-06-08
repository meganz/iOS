import Foundation

public protocol TransferUseCaseProtocol {
    func download(node: NodeEntity, to localUrl: URL, startHandler: ((TransferEntity) -> Void)?, progressHandler: ((TransferEntity) -> Void)?) async throws -> TransferEntity
    func uploadFile(at fileUrl: URL, to parent: NodeEntity, startHandler: ((TransferEntity) -> Void)?, progressHandler: ((TransferEntity) -> Void)?) async throws -> TransferEntity
}

public struct TransferUseCase<T: TransferRepositoryProtocol>: TransferUseCaseProtocol {
    
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func download(node: NodeEntity, to localUrl: URL, startHandler: ((TransferEntity) -> Void)? = nil, progressHandler: ((TransferEntity) -> Void)? = nil) async throws -> TransferEntity {
        try await repo.download(node: node, to: localUrl, startHandler: startHandler, progressHandler: progressHandler)
    }
    
    public func uploadFile(at fileUrl: URL, to parent: NodeEntity, startHandler: ((TransferEntity) -> Void)? = nil, progressHandler: ((TransferEntity) -> Void)? = nil) async throws -> TransferEntity {
        try await repo.uploadFile(at: fileUrl, to: parent, startHandler: startHandler, progressHandler: progressHandler)
    }
}
