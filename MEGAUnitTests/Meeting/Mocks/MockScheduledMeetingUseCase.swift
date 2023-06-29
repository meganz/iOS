@testable import MEGA
import MEGADomain

final class MockScheduledMeetingUseCase: ScheduledMeetingUseCaseProtocol {
    var scheduledMeetingsList: [ScheduledMeetingEntity]
    var scheduledMeetingsOccurrences: [ScheduledMeetingOccurrenceEntity]
    var upcomingOccurrences: [ChatIdEntity: ScheduledMeetingOccurrenceEntity]
    var createdScheduledMeeting: ScheduledMeetingEntity
    var createdScheduledMeetingError: ScheduleMeetingErrorEntity?
    var createScheduleMeetingEntity: CreateScheduleMeetingEntity?
    var updatedScheduledMeeting: ScheduledMeetingEntity
    var updatedScheduledMeetingError: ScheduleMeetingErrorEntity?
    
    init(
        scheduledMeetingsList: [ScheduledMeetingEntity] = [],
        scheduledMeetingsOccurrences: [ScheduledMeetingOccurrenceEntity] = [],
        upcomingOccurrences: [ChatIdEntity: ScheduledMeetingOccurrenceEntity] = [:],
        createdScheduledMeeting: ScheduledMeetingEntity = ScheduledMeetingEntity(),
        createdScheduledMeetingError: ScheduleMeetingErrorEntity? = nil,
        createScheduleMeetingEntity: CreateScheduleMeetingEntity? = nil,
        updatedScheduledMeeting: ScheduledMeetingEntity = ScheduledMeetingEntity(),
        updatedScheduledMeetingError: ScheduleMeetingErrorEntity? = nil
    ) {
        self.scheduledMeetingsList = scheduledMeetingsList
        self.scheduledMeetingsOccurrences = scheduledMeetingsOccurrences
        self.upcomingOccurrences = upcomingOccurrences
        self.createdScheduledMeeting = createdScheduledMeeting
        self.createdScheduledMeetingError = createdScheduledMeetingError
        self.createScheduleMeetingEntity = createScheduleMeetingEntity
        self.updatedScheduledMeeting = updatedScheduledMeeting
        self.updatedScheduledMeetingError = updatedScheduledMeetingError
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
    
    func createScheduleMeeting(_ meeting: CreateScheduleMeetingEntity) async throws -> ScheduledMeetingEntity {
        createScheduleMeetingEntity = meeting
        if let createdScheduledMeetingError {
            throw createdScheduledMeetingError
        } else {
            return createdScheduledMeeting
        }
    }
    
    func updateScheduleMeeting(_ meeting: ScheduledMeetingEntity, withChanges changes: ScheduledMeetingChangesEntity) async throws -> ScheduledMeetingEntity {
        if let updatedScheduledMeetingError {
            throw updatedScheduledMeetingError
        } else {
            return updatedScheduledMeeting
        }
    }
    
    func updateScheduleMeetingOccurrence(_ occurrence: ScheduledMeetingOccurrenceEntity, inChatRoom chatRoom: ChatRoomEntity, withChanges changes: ScheduledMeetingOccurrenceChangesEntity) async throws -> ScheduledMeetingEntity {
        if let updatedScheduledMeetingError {
            throw updatedScheduledMeetingError
        } else {
            return updatedScheduledMeeting
        }
    }
}
