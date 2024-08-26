import MEGADomain
import MEGASwift

public struct MockCallUpdateUseCase: CallUpdateUseCaseProtocol {
    private let monitorCallUpdateSequenceResult: AnyAsyncSequence<CallEntity>

    public init(
        monitorCallUpdateSequenceResult: AnyAsyncSequence<CallEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.monitorCallUpdateSequenceResult = monitorCallUpdateSequenceResult
    }
    
    public func monitorOnCallUpdate() -> AnyAsyncSequence<CallEntity> {
        monitorCallUpdateSequenceResult
            .eraseToAnyAsyncSequence()
    }
}
