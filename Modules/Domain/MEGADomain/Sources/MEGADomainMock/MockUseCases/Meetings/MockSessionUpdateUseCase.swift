import MEGADomain
import MEGASwift

public struct MockSessionUpdateUseCase: SessionUpdateUseCaseProtocol {
    private let monitorSessionUpdateSequenceResult: AnyAsyncSequence<ChatSessionEntity>
    private let sessionUpdateContinuation: AsyncStream<ChatSessionEntity>.Continuation

    public init() {
        let (stream, continuation) = AsyncStream
            .makeStream(of: ChatSessionEntity.self)
        self.monitorSessionUpdateSequenceResult = AnyAsyncSequence(stream)
        self.sessionUpdateContinuation = continuation
    }
    
    public func monitorOnSessionUpdate() -> AnyAsyncSequence<ChatSessionEntity> {
        monitorSessionUpdateSequenceResult
            .eraseToAnyAsyncSequence()
    }
    
    public func sendSessionUpdate(_ session: ChatSessionEntity) async throws {
        sessionUpdateContinuation.yield(session)
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
