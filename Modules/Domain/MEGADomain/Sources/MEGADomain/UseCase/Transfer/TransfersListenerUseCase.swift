import Foundation
import MEGASwift

public protocol TransfersListenerUseCaseProtocol: Sendable {
    /// Async sequence of transfer objects
    /// Callers can listen to this sequence using a `for await ...` loop and can terminate the sequence by cancelling the containing concurrent task.
    var completedTransfers: AnyAsyncSequence<TransferEntity> { get }
}

// MARK: - Use case implementation -
public struct TransfersListenerUseCase<T: TransfersListenerRepositoryProtocol>: TransfersListenerUseCaseProtocol {
    public var completedTransfers: AnyAsyncSequence<TransferEntity> {
        repo.completedTransfers
    }
        
    private var repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
}
