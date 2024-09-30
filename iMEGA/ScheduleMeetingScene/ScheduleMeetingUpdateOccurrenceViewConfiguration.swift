import ChatRepo
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n

final class ScheduleMeetingUpdateOccurrenceViewConfiguration: ScheduleMeetingUpdateViewConfiguration {
    
    override var upgradeButtonTappedEvent: any EventIdentifier {
        EditSingleOccurrenceMeetingMaxDurationReachedEvent()
    }
    
    let occurrence: ScheduledMeetingOccurrenceEntity
    
    override var startDate: Date { occurrence.startDate }
    override var endDate: Date { occurrence.endDate }
    
    override var shouldAllowEditingMeetingName: Bool { false }
    override var shouldAllowEditingRecurrenceOption: Bool { false }
    override var shouldAllowEditingEndRecurrenceOption: Bool { false }
    override var shouldAllowEditingMeetingLink: Bool { false }
    override var shouldAllowEditingParticipants: Bool { false }
    override var shouldAllowEditingCalendarInvite: Bool { false }
    override var shouldAllowEditingWaitingRoom: Bool { false }
    override var shouldAllowEditingAllowNonHostsToAddParticipants: Bool { false }
    override var shouldAllowEditingMeetingDescription: Bool { false }
    
    init(
        occurrence: ScheduledMeetingOccurrenceEntity,
        scheduledMeeting: ScheduledMeetingEntity,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatLinkUseCase: some ChatLinkUseCaseProtocol,
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol
    ) {
        self.occurrence = occurrence
        super.init(
            scheduledMeeting: scheduledMeeting,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
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
            occurrence: occurrence,
            parent: scheduledMeeting
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
    
    override var trackingEvents: ScheduleMeetingViewModel.TrackingEvents {
        .editOccurence
    }
}
