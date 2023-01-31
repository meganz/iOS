
public protocol ScheduledMeetingUseCaseProtocol {
    func scheduledMeetings() -> [ScheduledMeetingEntity]
    func scheduledMeetingsByChat(chatId: ChatIdEntity) -> [ScheduledMeetingEntity]
    func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity) async throws -> [ScheduledMeetingOccurrenceEntity]
}

public struct ScheduledMeetingUseCase<T: ScheduledMeetingRepositoryProtocol>: ScheduledMeetingUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func scheduledMeetings() -> [ScheduledMeetingEntity] {
        repository.scheduledMeetings()
    }
    
    public func scheduledMeetingsByChat(chatId: ChatIdEntity) -> [ScheduledMeetingEntity] {
        repository.scheduledMeetingsByChat(chatId: chatId)
    }
    
    public func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity) async throws -> [ScheduledMeetingOccurrenceEntity] {
        try await repository.scheduledMeetingOccurrencesByChat(chatId: chatId)
    }
}
