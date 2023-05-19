import Combine
import MEGADomain

protocol MeetingNoUserJoinedUseCaseProtocol {
    var monitor: AnyPublisher<Void, Never> { get }
    func start(timerDuration duration: TimeInterval, chatId: HandleEntity)
}

struct MeetingNoUserJoinedUseCase: MeetingNoUserJoinedUseCaseProtocol {
    private enum Constants {
        static let timerDuration: TimeInterval = 300 // 5 minutes
    }
    
    private let repository: MeetingNoUserJoinedRepositoryProtocol
    
    var monitor: AnyPublisher<Void, Never> {
        repository.monitor
    }
    
    init(repository: MeetingNoUserJoinedRepositoryProtocol) {
        self.repository = repository
    }
    
    func start(timerDuration duration: TimeInterval = Constants.timerDuration, chatId: HandleEntity) {
        repository.start(timerDuration: duration, chatId: chatId)
    }
}
