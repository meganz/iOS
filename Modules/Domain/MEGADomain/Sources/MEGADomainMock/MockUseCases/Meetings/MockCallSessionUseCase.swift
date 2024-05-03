import Combine
import MEGADomain

public struct MockCallSessionUseCase: CallSessionUseCaseProtocol {
    public var callSessionUpdateSubject: PassthroughSubject<(ChatSessionEntity, CallEntity), Never>

    public init(
        callSessionSubject: PassthroughSubject<(ChatSessionEntity, CallEntity), Never> = .init()
    ) {
        self.callSessionUpdateSubject = callSessionSubject
    }
        
    public mutating func onCallSessionUpdate() -> AnyPublisher<(ChatSessionEntity, CallEntity), Never> {
        callSessionUpdateSubject.eraseToAnyPublisher()
    }
}
