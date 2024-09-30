import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n

final class ScheduleMeetingNewViewConfiguration: ScheduleMeetingViewConfigurable {
    
    var upgradeButtonTappedEvent: any EventIdentifier {
        CreateMeetingMaxDurationReachedEvent()
    }
    
    var title: String { Strings.Localizable.Meetings.StartConversation.ContextMenu.scheduleMeeting }
    var type: ScheduleMeetingViewConfigurationType { .new }
    var meetingName: String { "" }
    lazy var startDate: Date = nextDateMinutesIsFiveMultiple(Date())
    lazy var endDate: Date = startDate.addingTimeInterval(1800)
    var meetingDescription: String { "" }
    var calendarInviteEnabled: Bool { false }
    var waitingRoomEnabled: Bool { false }
    var allowNonHostsToAddParticipantsEnabled: Bool { false }
    var participantHandleList: [HandleEntity] { [] }
    var rules: ScheduledMeetingRulesEntity { .init(frequency: .invalid) }
    var meetingLinkEnabled: Bool = false

    var shouldAllowEditingMeetingName: Bool { true }
    var shouldAllowEditingRecurrenceOption: Bool { true }
    var shouldAllowEditingEndRecurrenceOption: Bool { true }
    var shouldAllowEditingMeetingLink: Bool { true }
    var shouldAllowEditingParticipants: Bool { true }
    var shouldAllowEditingCalendarInvite: Bool { true }
    var shouldAllowEditingWaitingRoom: Bool { true }
    var shouldAllowEditingAllowNonHostsToAddParticipants: Bool { true }
    var shouldAllowEditingMeetingDescription: Bool { true }

    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let chatLinkUseCase: any ChatLinkUseCaseProtocol
    
    init(
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatLinkUseCase: some ChatLinkUseCaseProtocol,
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol
    ) {
        self.chatRoomUseCase = chatRoomUseCase
        self.chatLinkUseCase = chatLinkUseCase
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
    }
    
    func updateMeetingLinkEnabled() async {
        meetingLinkEnabled = false
    }
    
    func submit(meeting: ScheduleMeetingProxyEntity) async throws -> ScheduleMeetingViewConfigurationCompletion {
        let scheduledMeeting = try await scheduledMeetingUseCase.createScheduleMeeting(meeting)
        try await createMeetingLinkIfNeeded(for: scheduledMeeting, proxy: meeting)
        
        return .showMessageAndNavigateToInfo(
            message: Strings.Localizable.Meetings.ScheduleMeeting.meetingCreated,
            scheduledMeeting: scheduledMeeting
        )
    }
    
    private func nextDateMinutesIsFiveMultiple(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute, .day, .month, .year], from: date)
        guard let minutes = components.minute else {
            return date
        }
        components.minute = (minutes + 4) / 5 * 5
        return calendar.date(from: components) ?? date
    }

    private func createMeetingLinkIfNeeded(
        for scheduledMeeting: ScheduledMeetingEntity,
        proxy meeting: ScheduleMeetingProxyEntity
    ) async throws {
        guard meeting.meetingLinkEnabled else { return }
        let chatLink = try await createMeetingLink(for: scheduledMeeting)
        MEGALogInfo("New chatlink generated: \(chatLink)")
    }
    
    private func createMeetingLink(for scheduledMeeting: ScheduledMeetingEntity) async throws -> String {
        try await chatLinkUseCase.createChatLink(for: try chatRoom(for: scheduledMeeting))
    }
    
    private func chatRoom(for scheduledMeeting: ScheduledMeetingEntity) throws -> ChatRoomEntity {
        guard let chatRoom = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId) else {
            throw ChatRoomErrorEntity.noChatRoomFound
        }
        
        return chatRoom
    }
    
    var trackingEvents: ScheduleMeetingViewModel.TrackingEvents {
        .newMeeting
    }
}
