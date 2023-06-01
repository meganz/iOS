import Foundation

public protocol ScheduledMeetingUseCaseProtocol {
    func scheduledMeetings() -> [ScheduledMeetingEntity]
    func scheduledMeetingsByChat(chatId: ChatIdEntity) -> [ScheduledMeetingEntity]
    func scheduledMeetings(by chatId: ChatIdEntity) async -> [ScheduledMeetingEntity]
    func scheduledMeeting(for scheduledMeetingId: ChatIdEntity, chatId: ChatIdEntity) -> ScheduledMeetingEntity?
    func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity) async throws -> [ScheduledMeetingOccurrenceEntity]
    func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity, since: Date) async throws -> [ScheduledMeetingOccurrenceEntity]
    func upcomingOccurrences(forScheduledMeetings meetings: [ScheduledMeetingEntity]) async throws -> [ChatIdEntity : ScheduledMeetingOccurrenceEntity]
    func createScheduleMeeting(_ meeting: CreateScheduleMeetingEntity) async throws -> ScheduledMeetingEntity
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
    
    public func scheduledMeetings(by chatId: ChatIdEntity) async -> [ScheduledMeetingEntity] {
        repository.scheduledMeetingsByChat(chatId: chatId)
    }
    
    public func scheduledMeeting(for scheduledMeetingId: ChatIdEntity, chatId: ChatIdEntity) -> ScheduledMeetingEntity? {
        repository.scheduledMeeting(for: scheduledMeetingId, chatId: chatId)
    }
    
    public func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity) async throws -> [ScheduledMeetingOccurrenceEntity] {
        try await repository.scheduledMeetingOccurrencesByChat(chatId: chatId)
    }
    
    public func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity, since: Date) async throws -> [ScheduledMeetingOccurrenceEntity] {
        try await repository.scheduledMeetingOccurrencesByChat(chatId: chatId, since: since)
    }
    
    public func upcomingOccurrences(forScheduledMeetings meetings: [ScheduledMeetingEntity]) async throws -> [ChatIdEntity : ScheduledMeetingOccurrenceEntity] {
        var futureMeetingDates = [ChatIdEntity : ScheduledMeetingOccurrenceEntity]()
        
        for meeting in meetings where meeting.rules.frequency != .invalid {
            let occurrences = try await scheduledMeetingOccurrencesByChat(chatId: meeting.chatId, since: Date())
            if let nextOccurrence = occurrences.first(where: { !$0.cancelled }) {
                futureMeetingDates[meeting.scheduledId] = nextOccurrence
            }
        }
            
        return futureMeetingDates
    }
    
    public func createScheduleMeeting(_ meeting: CreateScheduleMeetingEntity) async throws -> ScheduledMeetingEntity {
        try await repository.createScheduleMeeting(meeting)
    }
}
