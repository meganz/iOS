import Combine
import Foundation

public protocol MeetingNoUserJoinedUseCaseProtocol: Sendable {
    var monitor: AnyPublisher<Void, Never> { get }
    func start(timerDuration duration: TimeInterval, chatId: HandleEntity)
}

public struct MeetingNoUserJoinedUseCase: MeetingNoUserJoinedUseCaseProtocol {
    public enum Constants {
        public static let timerDuration: TimeInterval = 5 * 60
    }
    
    private let repository: any MeetingNoUserJoinedRepositoryProtocol
    
    public var monitor: AnyPublisher<Void, Never> {
        repository.monitor
    }
    
    public init(repository: some MeetingNoUserJoinedRepositoryProtocol) {
        self.repository = repository
    }
    
    public func start(timerDuration duration: TimeInterval = Constants.timerDuration, chatId: HandleEntity) {
        repository.start(timerDuration: duration, chatId: chatId)
    }
}
