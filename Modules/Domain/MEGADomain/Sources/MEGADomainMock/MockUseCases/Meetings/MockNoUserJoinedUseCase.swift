import Combine
import Foundation
import MEGADomain

public struct MockMeetingNoUserJoinedUseCase: MeetingNoUserJoinedUseCaseProtocol {
    private let passthroughSubject = PassthroughSubject<Void, Never>()
    
    public init() {}

    public var monitor: AnyPublisher<Void, Never> {
        passthroughSubject.eraseToAnyPublisher()
    }
    
    public func start(timerDuration duration: TimeInterval, chatId: HandleEntity) {
        passthroughSubject.send()
    }
}
