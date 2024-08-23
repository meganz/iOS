import Foundation
import MEGASwift

public protocol NodeTransferUseCaseProtocol: Sendable {
    var nodeTransferCompletionUpdates: AnyAsyncSequence<TransferEntity> { get }
}

public struct NodeTransferUseCase<T: NodeTransferRepositoryProtocol>: NodeTransferUseCaseProtocol {
    private let repo: T
    
    public var nodeTransferCompletionUpdates: AnyAsyncSequence<TransferEntity> {
        repo.nodeTransferCompletionUpdates
    }
    
    public init(repo: T) {
        self.repo = repo
    }
}
