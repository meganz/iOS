import Combine
@testable import MEGA
import MEGADomain

struct MockCallSessionUseCase: CallSessionUseCaseProtocol {
    var callSessionUpdateSubject: PassthroughSubject<ChatSessionEntity, Never>

    init(
        callSessionSubject: PassthroughSubject<ChatSessionEntity, Never> = .init()
    ) {
        self.callSessionUpdateSubject = callSessionSubject
    }
        
    mutating func onCallSessionUpdate() -> AnyPublisher<MEGADomain.ChatSessionEntity, Never> {
        callSessionUpdateSubject.eraseToAnyPublisher()
    }
}
