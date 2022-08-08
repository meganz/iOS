@testable import MEGA
import Combine
import MEGADomain

struct MockMeetingNoUserJoinedUseCase: MeetingNoUserJoinedUseCaseProtocol {
    private let passthroughSubject = PassthroughSubject<Void, Never>()

    var monitor: AnyPublisher<Void, Never> {
        passthroughSubject.eraseToAnyPublisher()
    }
    
    func start(timerDuration duration: TimeInterval, chatId: HandleEntity) {
        passthroughSubject.send()
    }
}
