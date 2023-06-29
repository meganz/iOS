import MEGADomain

enum ScheduleMeetingViewConfigurationType {
    case new
    case edit
}

enum ScheduleMeetingViewConfigurationCompletion {
    case showMessageForScheduleMeeting(message: String, scheduledMeeting: ScheduledMeetingEntity)
    case showMessageForOccurrence(message: String, occurrence: ScheduledMeetingOccurrenceEntity)
    case showMessageAndNavigateToInfo(message: String, scheduledMeeting: ScheduledMeetingEntity)
}

protocol ScheduleMeetingViewConfigurable {
    var type: ScheduleMeetingViewConfigurationType { get }
    var meetingName: String { get }
    var startDate: Date { get }
    var endDate: Date { get }
    var meetingDescription: String { get }
    var calendarInviteEnabled: Bool { get }
    var allowNonHostsToAddParticipantsEnabled: Bool { get }
    var participantHandleList: [HandleEntity] { get }
    var rules: ScheduledMeetingRulesEntity { get }
    var meetingLinkEnabled: Bool { get }
    
    var shouldAllowEditingMeetingName: Bool { get }
    var shouldAllowEditingRecurrenceOption: Bool { get }
    var shouldAllowEditingEndRecurrenceOption: Bool { get }
    var shouldAllowEditingMeetingLink: Bool { get }
    var shouldAllowEditingParticipants: Bool { get }
    var shouldAllowEditingCalendarInvite: Bool { get }
    var shouldAllowEditingAllowNonHostsToAddParticipants: Bool { get }
    var shouldAllowEditingMeetingDescription: Bool { get }
    
    func updateMeetingLinkEnabled() async
    func submit(meeting: ScheduleMeetingProxyEntity) async throws -> ScheduleMeetingViewConfigurationCompletion
}
