
import Combine
import MEGADomain

protocol MeetingNoUserJoinedRepositoryProtocol {
    static var sharedRepo: Self { get }
    var monitor: AnyPublisher<Void, Never> { get }
    func start(timerDuration duration: TimeInterval, chatId: HandleEntity)
}
