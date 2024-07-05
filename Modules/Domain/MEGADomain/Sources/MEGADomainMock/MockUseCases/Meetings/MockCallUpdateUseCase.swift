import MEGADomain
import MEGASwift

public struct MockCallUpdateUseCase: CallUpdateUseCaseProtocol {
    private let monitorCallUpdateSequenceResult: AnyAsyncThrowingSequence<CallEntity, any Error>

    public init(
        monitorCallUpdateSequenceResult: AnyAsyncThrowingSequence<CallEntity, any Error> = EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence()
    ) {
        self.monitorCallUpdateSequenceResult = monitorCallUpdateSequenceResult
    }
    
    public func monitorOnCallUpdate() -> AnyAsyncThrowingSequence<CallEntity, any Error> {
        monitorCallUpdateSequenceResult
            .eraseToAnyAsyncThrowingSequence()
    }
}
