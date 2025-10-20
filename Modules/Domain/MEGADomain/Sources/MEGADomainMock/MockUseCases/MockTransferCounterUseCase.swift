import MEGADomain
import MEGASwift

public final class MockTransferCounterUseCase: TransferCounterUseCaseProtocol {
    private let transferStartSubject = AsyncStream<TransferEntity>.makeStream()
    private let transferUpdateSubject = AsyncStream<TransferEntity>.makeStream()
    private let transferFinishSubject = AsyncStream<TransferResponseEntity>.makeStream()
    private let transferTemporaryErrorSubject = AsyncStream<TransferResponseEntity>.makeStream()
    
    public init() { }
    
    public var transferStartUpdates: AnyAsyncSequence<TransferEntity> {
        transferStartSubject.stream.eraseToAnyAsyncSequence()
    }
    
    public var transferUpdates: AnyAsyncSequence<TransferEntity> {
        transferUpdateSubject.stream.eraseToAnyAsyncSequence()
    }
    
    public var transferTemporaryErrorUpdates: AnyAsyncSequence<TransferResponseEntity> {
        transferTemporaryErrorSubject.stream.eraseToAnyAsyncSequence()
    }
    
    public var transferFinishUpdates: AnyAsyncSequence<TransferResponseEntity> {
        transferFinishSubject.stream.eraseToAnyAsyncSequence()
    }
    
    public func triggerTransferStart(_ transfer: TransferEntity) async {
        transferStartSubject.continuation.yield(transfer)
    }
    
    public func triggerTransferUpdate(_ transfer: TransferEntity) async {
        transferUpdateSubject.continuation.yield(transfer)
    }
    
    public func triggerTransferFinish(_ transferEntity: TransferEntity) async {
        let mockError = ErrorEntity(type: .ok)
        let response = TransferResponseEntity(transferEntity: transferEntity, error: mockError)
        transferFinishSubject.continuation.yield(response)
    }
    
    public func triggerTransferTemporaryError(_ transferEntity: TransferEntity, errorType: ErrorTypeEntity = .ok) async {
        let mockError = ErrorEntity(type: errorType)
        let response = TransferResponseEntity(transferEntity: transferEntity, error: mockError)
        transferTemporaryErrorSubject.continuation.yield(response)
    }
}
