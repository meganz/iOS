import Combine
import Foundation
import MEGADomain

public class MockMeetingNoUserJoinedUseCase: MeetingNoUserJoinedUseCaseProtocol {
    private let passthroughSubject = PassthroughSubject<Void, Never>()
    public var startTimer_calledTimes = 0

    public init() {}

    public var monitor: AnyPublisher<Void, Never> {
        passthroughSubject.eraseToAnyPublisher()
    }
    
    public func start(timerDuration duration: TimeInterval, chatId: HandleEntity) {
        startTimer_calledTimes += 1
        passthroughSubject.send()
    }
}
