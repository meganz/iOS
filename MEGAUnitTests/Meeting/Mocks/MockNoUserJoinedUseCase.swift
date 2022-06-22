@testable import MEGA
import Combine

struct MockMeetingNoUserJoinedUseCase: MeetingNoUserJoinedUseCaseProtocol {
    private let passthroughSubject = PassthroughSubject<Void, Never>()

    var monitor: AnyPublisher<Void, Never> {
        passthroughSubject.eraseToAnyPublisher()
    }
    
    func start(timerDuration duration: TimeInterval, chatId: MEGAHandle) {
        passthroughSubject.send()
    }
}
