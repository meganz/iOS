@testable import MEGA
import MEGADomain

struct MockScheduledMeetingUseCase: ScheduledMeetingUseCaseProtocol {
    var scheduledMeetingsList: [ScheduledMeetingEntity] = []
    var scheduledMeetingsOccurrences: [ScheduledMeetingOccurrenceEntity] = []

    func scheduledMeetings() -> [ScheduledMeetingEntity] {
        scheduledMeetingsList
    }
    
    func scheduledMeetingsByChat(chatId: ChatIdEntity) -> [MEGADomain.ScheduledMeetingEntity] {
        scheduledMeetingsList
    }
    
    func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity) async throws -> [ScheduledMeetingOccurrenceEntity] {
        scheduledMeetingsOccurrences
    }
}
