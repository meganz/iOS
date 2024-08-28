import MEGADomain
import MEGASwift

public struct MockCallUpdateUseCase: CallUpdateUseCaseProtocol {
    private let monitorCallUpdateSequenceResult: AnyAsyncSequence<CallEntity>
    private let callUpdateContinuation: AsyncStream<CallEntity>.Continuation
    
    public init() {
        let (stream, continuation) = AsyncStream
            .makeStream(of: CallEntity.self)
        self.monitorCallUpdateSequenceResult = AnyAsyncSequence(stream)
        self.callUpdateContinuation = continuation
    }
    
    public func monitorOnCallUpdate() -> AnyAsyncSequence<CallEntity> {
        monitorCallUpdateSequenceResult
            .eraseToAnyAsyncSequence()
    }
    
    public func sendCallUpdate(_ call: CallEntity) async throws {
        callUpdateContinuation.yield(call)
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
