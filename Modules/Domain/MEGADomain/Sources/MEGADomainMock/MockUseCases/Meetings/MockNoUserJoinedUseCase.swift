@preconcurrency import Combine
import Foundation
import MEGADomain
import MEGASwift

public final class MockMeetingNoUserJoinedUseCase: MeetingNoUserJoinedUseCaseProtocol, @unchecked Sendable {
    private let passthroughSubject = PassthroughSubject<Void, Never>()
    
    @Atomic
    public var _startTimer_calledTimes = 0
    
    public var startTimer_calledTimes: Int {
        $_startTimer_calledTimes.wrappedValue
    }

    public init() {}

    public var monitor: AnyPublisher<Void, Never> {
        passthroughSubject.eraseToAnyPublisher()
    }
    
    public func start(timerDuration duration: TimeInterval, chatId: HandleEntity) {
        $_startTimer_calledTimes.mutate { $0 += 1 }
        passthroughSubject.send()
    }
}
