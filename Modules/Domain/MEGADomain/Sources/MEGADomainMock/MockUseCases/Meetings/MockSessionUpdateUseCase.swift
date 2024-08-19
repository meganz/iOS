import MEGADomain
import MEGASwift

public struct MockSessionUpdateUseCase: SessionUpdateUseCaseProtocol {
    private let monitorSessionUpdateSequenceResult: AnyAsyncThrowingSequence<ChatSessionEntity, any Error>

    public init(
        monitorSessionUpdateSequenceResult: AnyAsyncThrowingSequence<ChatSessionEntity, any Error> = EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence()
    ) {
        self.monitorSessionUpdateSequenceResult = monitorSessionUpdateSequenceResult
    }
    
    public func monitorOnSessionUpdate() -> AnyAsyncThrowingSequence<ChatSessionEntity, any Error> {
        monitorSessionUpdateSequenceResult
            .eraseToAnyAsyncThrowingSequence()
    }
}
