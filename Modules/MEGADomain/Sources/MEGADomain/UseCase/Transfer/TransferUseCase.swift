import Foundation

public protocol TransferUseCaseProtocol {
    func download(node: NodeEntity, to localUrl: URL) async throws -> TransferEntity
    func uploadFile(at fileUrl: URL, to parent: NodeEntity) async throws -> TransferEntity
}

public struct TransferUseCase<T: TransferRepositoryProtocol>: TransferUseCaseProtocol {
    
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func download(node: NodeEntity, to localUrl: URL) async throws -> TransferEntity {
        try await repo.download(node: node, to: localUrl)
    }
    
    public func uploadFile(at fileUrl: URL, to parent: NodeEntity) async throws -> TransferEntity {
        try await repo.uploadFile(at: fileUrl, to: parent)
    }
}
