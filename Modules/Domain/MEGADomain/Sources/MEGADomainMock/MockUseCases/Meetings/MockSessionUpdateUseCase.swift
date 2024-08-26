import MEGADomain
import MEGASwift

public struct MockSessionUpdateUseCase: SessionUpdateUseCaseProtocol {
    private let monitorSessionUpdateSequenceResult: AnyAsyncSequence<ChatSessionEntity>

    public init(
        monitorSessionUpdateSequenceResult: AnyAsyncSequence<ChatSessionEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.monitorSessionUpdateSequenceResult = monitorSessionUpdateSequenceResult
    }
    
    public func monitorOnSessionUpdate() -> AnyAsyncSequence<ChatSessionEntity> {
        monitorSessionUpdateSequenceResult
            .eraseToAnyAsyncSequence()
    }
}
