
import Combine
import MEGADomain

protocol MeetingNoUserJoinedRepositoryProtocol: RepositoryProtocol {
    var monitor: AnyPublisher<Void, Never> { get }
    func start(timerDuration duration: TimeInterval, chatId: MEGAHandle)
}
