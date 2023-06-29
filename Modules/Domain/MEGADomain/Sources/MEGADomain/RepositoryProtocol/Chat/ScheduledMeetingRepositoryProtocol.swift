import Foundation

public protocol ScheduledMeetingRepositoryProtocol: RepositoryProtocol {
    func scheduledMeetings() -> [ScheduledMeetingEntity]
    func scheduledMeetingsByChat(chatId: ChatIdEntity) -> [ScheduledMeetingEntity]
    func scheduledMeeting(for scheduledMeetingId: ChatIdEntity, chatId: ChatIdEntity) -> ScheduledMeetingEntity?
    func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity) async throws -> [ScheduledMeetingOccurrenceEntity]
    func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity, since: Date) async throws -> [ScheduledMeetingOccurrenceEntity]
    func createScheduleMeeting(_ meeting: CreateScheduleMeetingEntity) async throws -> ScheduledMeetingEntity
    func updateScheduleMeeting(_ meeting: ScheduledMeetingEntity, withChanges changes: ScheduledMeetingChangesEntity) async throws -> ScheduledMeetingEntity
    func updateScheduleMeetingOccurrence(_ occurrence: ScheduledMeetingOccurrenceEntity, inChatRoom chatRoom: ChatRoomEntity, withChanges changes: ScheduledMeetingOccurrenceChangesEntity) async throws -> ScheduledMeetingEntity
}
