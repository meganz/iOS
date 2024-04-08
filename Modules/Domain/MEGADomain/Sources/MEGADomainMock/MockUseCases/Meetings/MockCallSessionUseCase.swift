import Combine
import MEGADomain

public struct MockCallSessionUseCase: CallSessionUseCaseProtocol {
    public var callSessionUpdateSubject: PassthroughSubject<ChatSessionEntity, Never>

    public init(
        callSessionSubject: PassthroughSubject<ChatSessionEntity, Never> = .init()
    ) {
        self.callSessionUpdateSubject = callSessionSubject
    }
        
    public mutating func onCallSessionUpdate() -> AnyPublisher<ChatSessionEntity, Never> {
        callSessionUpdateSubject.eraseToAnyPublisher()
    }
}
