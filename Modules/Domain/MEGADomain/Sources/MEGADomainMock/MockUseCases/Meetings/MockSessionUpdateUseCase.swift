import MEGADomain
import MEGASwift

public struct MockSessionUpdateUseCase: SessionUpdateUseCaseProtocol {
    private let monitorSessionUpdateSequenceResult: AnyAsyncSequence<(ChatSessionEntity, CallEntity)>
    private let sessionUpdateContinuation: AsyncStream<(ChatSessionEntity, CallEntity)>.Continuation

    public init() {
        let (stream, continuation) = AsyncStream<(ChatSessionEntity, CallEntity)>
            .makeStream(of: (ChatSessionEntity, CallEntity).self)
        self.monitorSessionUpdateSequenceResult = AnyAsyncSequence(stream)
        self.sessionUpdateContinuation = continuation
    }
    
    public func monitorOnSessionUpdate() -> AnyAsyncSequence<(ChatSessionEntity, CallEntity)> {
        monitorSessionUpdateSequenceResult
            .eraseToAnyAsyncSequence()
    }
    
    public func sendSessionUpdate(_ session: (ChatSessionEntity, CallEntity)) {
        sessionUpdateContinuation.yield(session)
    }
}
