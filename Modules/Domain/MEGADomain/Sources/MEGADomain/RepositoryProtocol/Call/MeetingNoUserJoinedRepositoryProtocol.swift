import Combine
import Foundation

public protocol MeetingNoUserJoinedRepositoryProtocol: RepositoryProtocol {
    var monitor: AnyPublisher<Void, Never> { get }
    func start(timerDuration duration: TimeInterval, chatId: HandleEntity)
}
