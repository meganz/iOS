import Combine
import Foundation

public protocol NodeTransferUseCaseProtocol: Sendable {
    func transferResultPublisher() -> AnyPublisher<Result<TransferEntity, TransferErrorEntity>, Never>
    func registerMEGATransferDelegate() async
    func deRegisterMEGATransferDelegate() async
    func registerMEGASharedFolderTransferDelegate() async
    func deRegisterMEGASharedFolderTransferDelegate() async
}

public struct NodeTransferUseCase<T: NodeTransferRepositoryProtocol>: NodeTransferUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func registerMEGATransferDelegate() async {
        await repo.registerMEGATransferDelegate()
    }
    
    public func deRegisterMEGATransferDelegate() async {
        await repo.deRegisterMEGATransferDelegate()
    }
    
    public func registerMEGASharedFolderTransferDelegate() async {
        await repo.registerMEGASharedFolderTransferDelegate()
    }
    
    public func deRegisterMEGASharedFolderTransferDelegate() async {
        await repo.deRegisterMEGASharedFolderTransferDelegate()
    }
    
    public func transferResultPublisher() -> AnyPublisher<Result<TransferEntity, TransferErrorEntity>, Never> {
        repo.transferResultPublisher
    }
}
