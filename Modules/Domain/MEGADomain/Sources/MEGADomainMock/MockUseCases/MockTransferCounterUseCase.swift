import MEGADomain
import MEGASwift

public final class MockTransferCounterUseCase: TransferCounterUseCaseProtocol {
    private let transferStartSubject = AsyncStream<TransferEntity>.makeStream()
    private let transferUpdateSubject = AsyncStream<TransferEntity>.makeStream()
    private let transferFinishSubject = AsyncStream<TransferResponseEntity>.makeStream()
    private let transferTemporaryErrorSubject = AsyncStream<TransferResponseEntity>.makeStream()

    private let injectedStartUpdates: AnyAsyncSequence<TransferEntity>?
    private let injectedUpdates: AnyAsyncSequence<TransferEntity>?
    private let injectedTemporaryErrorUpdates: AnyAsyncSequence<TransferResponseEntity>?
    private let injectedFinishUpdates: AnyAsyncSequence<TransferResponseEntity>?

    public var transferStartUpdates: AnyAsyncSequence<TransferEntity> {
        injectedStartUpdates ?? transferStartSubject.stream.eraseToAnyAsyncSequence()
    }

    public var transferUpdates: AnyAsyncSequence<TransferEntity> {
        injectedUpdates ?? transferUpdateSubject.stream.eraseToAnyAsyncSequence()
    }

    public var transferTemporaryErrorUpdates: AnyAsyncSequence<TransferResponseEntity> {
        injectedTemporaryErrorUpdates ?? transferTemporaryErrorSubject.stream.eraseToAnyAsyncSequence()
    }

    public var transferFinishUpdates: AnyAsyncSequence<TransferResponseEntity> {
        injectedFinishUpdates ?? transferFinishSubject.stream.eraseToAnyAsyncSequence()
    }
    
    public init(
        transferStartUpdates: AnyAsyncSequence<TransferEntity>? = nil,
        transferUpdates: AnyAsyncSequence<TransferEntity>? = nil,
        transferTemporaryErrorUpdates: AnyAsyncSequence<TransferResponseEntity>? = nil,
        transferFinishUpdates: AnyAsyncSequence<TransferResponseEntity>? = nil
    ) {
        injectedStartUpdates = transferStartUpdates
        injectedUpdates = transferUpdates
        injectedTemporaryErrorUpdates = transferTemporaryErrorUpdates
        injectedFinishUpdates = transferFinishUpdates
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
