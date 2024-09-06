@preconcurrency import Combine
import Foundation
import MEGADomain

public struct MockScheduledMeetingUseCase: ScheduledMeetingUseCaseProtocol {
    private let scheduledMeetingsList: [ScheduledMeetingEntity]
    private let scheduledMeetingsOccurrences: [ScheduledMeetingOccurrenceEntity]
    private let upcomingOccurrences: [ChatIdEntity: ScheduledMeetingOccurrenceEntity]
    private let scheduleMeetingError: ScheduleMeetingErrorEntity?
    private let meetingProxy: ScheduleMeetingProxyEntity?
    private let occurrencesShouldBeReloadSubject = PassthroughSubject<Bool, Never>()

    public init(
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
    
    public func scheduledMeetings() -> [ScheduledMeetingEntity] {
        scheduledMeetingsList
    }
    
    public func scheduledMeetingsByChat(chatId: ChatIdEntity) -> [ScheduledMeetingEntity] {
        scheduledMeetingsList
    }
    
    public func scheduledMeetings(by chatId: ChatIdEntity) async -> [ScheduledMeetingEntity] {
        scheduledMeetingsList
    }
    
    public func scheduledMeeting(for scheduledMeetingId: ChatIdEntity, chatId: ChatIdEntity) -> ScheduledMeetingEntity? {
        scheduledMeetingsList.first
    }
    
    public func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity) async throws -> [ScheduledMeetingOccurrenceEntity] {
        scheduledMeetingsOccurrences
    }
    
    public func scheduledMeetingOccurrencesByChat(chatId: ChatIdEntity, since: Date) async throws -> [MEGADomain.ScheduledMeetingOccurrenceEntity] {
        scheduledMeetingsOccurrences
    }
    
    public func upcomingOccurrences(forScheduledMeetings meetings: [ScheduledMeetingEntity]) async throws -> [ChatIdEntity: ScheduledMeetingOccurrenceEntity] {
        upcomingOccurrences
    }
    
    public func createScheduleMeeting(_ meeting: ScheduleMeetingProxyEntity) async throws -> ScheduledMeetingEntity {
        try firstMeeting()
    }
    
    public func updateScheduleMeeting(_ meeting: ScheduledMeetingEntity, updateChatTitle: Bool) async throws -> ScheduledMeetingEntity {
        try firstMeeting()
    }
    
    public func updateOccurrence(_ occurrence: ScheduledMeetingOccurrenceEntity, meeting: ScheduledMeetingEntity) async throws -> ScheduledMeetingEntity {
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
    
    public func occurrencesShouldBeReloadListener(forChatRoom chatRoom: ChatRoomEntity) -> AnyPublisher<Bool, Never> {
        occurrencesShouldBeReloadSubject.eraseToAnyPublisher()
    }
}
