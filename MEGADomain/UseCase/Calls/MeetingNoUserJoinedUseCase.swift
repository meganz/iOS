
import Combine

protocol MeetingNoUserJoinedUseCaseProtocol {
    var monitor: AnyPublisher<Void, Never> { get }
    func start(timerDuration duration: TimeInterval, chatId: MEGAHandle)
}

struct MeetingNoUserJoinedUseCase: MeetingNoUserJoinedUseCaseProtocol {
    private enum Constants {
        static let timerDuration: TimeInterval = 5 // 5 minutes
    }
    
    private let repository: MeetingNoUserJoinedRepositoryProtocol
    
    var monitor: AnyPublisher<Void, Never> {
        repository.monitor
    }
    
    init(repository: MeetingNoUserJoinedRepositoryProtocol) {
        self.repository = repository
    }
    
    func start(timerDuration duration: TimeInterval = Constants.timerDuration, chatId: MEGAHandle) {
        repository.start(timerDuration: duration, chatId: chatId)
    }
}

