
import Combine

protocol MeetingNoUserJoinedRepositoryProtocol {
    var monitor: AnyPublisher<Void, Never> { get }
    func start(timerDuration duration: TimeInterval, chatId: MEGAHandle)
}
