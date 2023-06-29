import MEGADomain

final class ScheduleMeetingUpdateOccurrenceViewConfiguration: ScheduleMeetingUpdateViewConfiguration {
    let occurrence: ScheduledMeetingOccurrenceEntity
    
    override var startDate: Date { occurrence.startDate }
    override var endDate: Date { occurrence.endDate }
    
    override var shouldAllowEditingMeetingName: Bool { false }
    override var shouldAllowEditingRecurrenceOption: Bool { false }
    override var shouldAllowEditingEndRecurrenceOption: Bool { false }
    override var shouldAllowEditingMeetingLink: Bool { false }
    override var shouldAllowEditingParticipants: Bool { false }
    override var shouldAllowEditingCalendarInvite: Bool { false }
    override var shouldAllowEditingAllowNonHostsToAddParticipants: Bool { false }
    override var shouldAllowEditingMeetingDescription: Bool { false }
    
    init(
        occurrence: ScheduledMeetingOccurrenceEntity,
        scheduledMeeting: ScheduledMeetingEntity,
        chatRoomUseCase: any ChatRoomUseCaseProtocol,
        chatLinkUseCase: any ChatLinkUseCaseProtocol,
        scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    ) {
        self.occurrence = occurrence
        super.init(
            scheduledMeeting: scheduledMeeting,
            chatRoomUseCase: chatRoomUseCase,
            chatLinkUseCase: chatLinkUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase
        )
    }
    
    override func submit(meeting: ScheduleMeetingProxyEntity) async throws -> ScheduleMeetingViewConfigurationCompletion {
        let occurrence = updatedOccurrence(for: meeting)
        _ = try await scheduledMeetingUseCase.updateOccurrence(occurrence, meeting: scheduledMeeting)
        return .showMessageForOccurrence(
            message: Strings.Localizable.Meetings.ScheduleMeeting.Occurrence.UpdateSuccessfull.popupMessage,
            occurrence: occurrence
        )
    }
    
    private func updatedOccurrence(for meeting: ScheduleMeetingProxyEntity) -> ScheduledMeetingOccurrenceEntity {
        ScheduledMeetingOccurrenceEntity(
            cancelled: occurrence.cancelled,
            scheduledId: occurrence.scheduledId,
            parentScheduledId: occurrence.parentScheduledId,
            overrides: UInt64(occurrence.startDate.timeIntervalSince1970),
            timezone: occurrence.timezone,
            startDate: meeting.startDate,
            endDate: meeting.endDate
        )
    }
}
