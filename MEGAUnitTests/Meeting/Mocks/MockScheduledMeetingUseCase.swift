@testable import MEGA
import MEGADomain

final class MockScheduledMeetingUseCase: ScheduledMeetingUseCaseProtocol {
    var scheduledMeetingsList: [ScheduledMeetingEntity]
    var scheduledMeetingsOccurrences: [ScheduledMeetingOccurrenceEntity]
    var upcomingOccurrences: [ChatIdEntity: ScheduledMeetingOccurrenceEntity]
    var scheduleMeetingError: ScheduleMeetingErrorEntity?
    var meetingProxy: ScheduleMeetingProxyEntity?
    
    init(
        scheduledMeetingsList: [ScheduledMeetingEntity] = [],
        scheduledMeetingsOccurrences: [ScheduledMeetingOccurrenceEntity] = [],
        upcomingOccurrences: [ChatIdEntity: ScheduledMeetingOccurrenceEntity] = [:],
        scheduleMeetingError: ScheduleMeetingErrorEntity? = nil,
        meetingProxy: ScheduleMeetingProxyEntity? = nil
    ) {
        self.scheduledMeetingsList = scheduledMeetingsList
        self.scheduledMeetingsOccurrences = scheduledMeetingsOccurrences
        self.upcomingOccurrences = upcomingOccurrences
        self.scheduleMeetingError = scheduleMeetingError
        self.meetingProxy = meetingProxy
    }
    
    func scheduledMeetings() -> [ScheduledMeetingEntity] {
        scheduledMeetingsList
    }
    
    func scheduledMeetingsByChat(chatId: ChatIdEntity) -> [ScheduledMeetingEntity] {
        scheduledMeetingsList
    }
    
    func scheduledMeetings(by chatId: ChatIdEntity) async -> [ScheduledMeetingEntity] {
        scheduledMeetingsList
    }
    
    func scheduledMeeting(for scheduledMeetingId: ChatIdEntity, chatId: ChatIdEntity) -> ScheduledMeetingEntity? {
        scheduledMeetingsList.first
    }
    
    func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity) async throws -> [ScheduledMeetingOccurrenceEntity] {
        scheduledMeetingsOccurrences
    }
    
    func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity, since: Date) async throws -> [MEGADomain.ScheduledMeetingOccurrenceEntity] {
        scheduledMeetingsOccurrences
    }
    
    func upcomingOccurrences(forScheduledMeetings meetings: [ScheduledMeetingEntity]) async throws -> [ChatIdEntity: ScheduledMeetingOccurrenceEntity] {
        upcomingOccurrences
    }
    
    func createScheduleMeeting(_ meeting: ScheduleMeetingProxyEntity) async throws -> ScheduledMeetingEntity {
        try firstMeeting()
    }
    
    func updateScheduleMeeting(_ meeting: ScheduledMeetingEntity) async throws -> ScheduledMeetingEntity {
       try firstMeeting()
    }
    
    func updateOccurrence(_ occurrence: ScheduledMeetingOccurrenceEntity, meeting: ScheduledMeetingEntity) async throws -> ScheduledMeetingEntity {
       try firstMeeting()
    }
    
    private func firstMeeting() throws -> ScheduledMeetingEntity {
        if let scheduledMeeting = scheduledMeetingsList.first {
            return scheduledMeeting
        } else if let scheduleMeetingError {
            throw scheduleMeetingError
        }
        
        return ScheduledMeetingEntity()
    }
}
