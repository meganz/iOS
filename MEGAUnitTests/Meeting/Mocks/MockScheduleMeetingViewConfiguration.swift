@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain

final class MockScheduleMeetingViewConfiguration: ScheduleMeetingViewConfigurable {
    
    class Event: EventIdentifier {
        init(
            eventName: String = "event",
            uniqueIdentifier: Int32 = 1
        ) {
            self.eventName = eventName
            self.uniqueIdentifier = uniqueIdentifier
        }
        
        var eventName: String
        var uniqueIdentifier: Int32
    }

    var title: String
    var type: ScheduleMeetingViewConfigurationType
    var meetingName: String
    var startDate: Date
    var endDate: Date
    var meetingDescription: String
    var calendarInviteEnabled: Bool
    var waitingRoomEnabled: Bool
    var allowNonHostsToAddParticipantsEnabled: Bool
    var participantHandleList: [HandleEntity]
    var rules: ScheduledMeetingRulesEntity
    var meetingLinkEnabled: Bool
    var shouldAllowEditingMeetingName: Bool
    var shouldAllowEditingRecurrenceOption: Bool
    var shouldAllowEditingEndRecurrenceOption: Bool
    var shouldAllowEditingMeetingLink: Bool
    var shouldAllowEditingParticipants: Bool
    var shouldAllowEditingCalendarInvite: Bool
    var shouldAllowEditingWaitingRoom: Bool
    var shouldAllowEditingAllowNonHostsToAddParticipants: Bool
    var shouldAllowEditingMeetingDescription: Bool
    var completion: ScheduleMeetingViewConfigurationCompletion
    var updateMeetingLinkEnabled_calledTimes = 0
    var upgradeButtonTappedEvent: any EventIdentifier {
        
        return Event()
    }
    
    nonisolated init(
        title: String = "",
        type: ScheduleMeetingViewConfigurationType = .new,
        meetingName: String = "",
        startDate: Date = Date(),
        endDate: Date = Date(),
        meetingDescription: String = "",
        calendarInviteEnabled: Bool = false,
        waitingRoomEnabled: Bool = false,
        allowNonHostsToAddParticipantsEnabled: Bool = false,
        participantHandleList: [HandleEntity] = [],
        rules: ScheduledMeetingRulesEntity = .init(frequency: .invalid),
        meetingLinkEnabled: Bool = false,
        shouldAllowEditingMeetingName: Bool = false,
        shouldAllowEditingRecurrenceOption: Bool = false,
        shouldAllowEditingEndRecurrenceOption: Bool = false,
        shouldAllowEditingMeetingLink: Bool = false,
        shouldAllowEditingParticipants: Bool = false,
        shouldAllowEditingCalendarInvite: Bool = false,
        shouldAllowEditingWaitingRoom: Bool = false,
        shouldAllowEditingAllowNonHostsToAddParticipants: Bool = false,
        shouldAllowEditingMeetingDescription: Bool = false,
        completion: ScheduleMeetingViewConfigurationCompletion = .showMessageForScheduleMeeting(
            message: "",
            scheduledMeeting: ScheduledMeetingEntity()
        )
    ) {
        self.title = title
        self.type = type
        self.meetingName = meetingName
        self.startDate = startDate
        self.endDate = endDate
        self.meetingDescription = meetingDescription
        self.calendarInviteEnabled = calendarInviteEnabled
        self.waitingRoomEnabled = waitingRoomEnabled
        self.allowNonHostsToAddParticipantsEnabled = allowNonHostsToAddParticipantsEnabled
        self.participantHandleList = participantHandleList
        self.rules = rules
        self.meetingLinkEnabled = meetingLinkEnabled
        self.shouldAllowEditingMeetingName = shouldAllowEditingMeetingName
        self.shouldAllowEditingRecurrenceOption = shouldAllowEditingRecurrenceOption
        self.shouldAllowEditingEndRecurrenceOption = shouldAllowEditingEndRecurrenceOption
        self.shouldAllowEditingMeetingLink = shouldAllowEditingMeetingLink
        self.shouldAllowEditingParticipants = shouldAllowEditingParticipants
        self.shouldAllowEditingCalendarInvite = shouldAllowEditingCalendarInvite
        self.shouldAllowEditingWaitingRoom = shouldAllowEditingWaitingRoom
        self.shouldAllowEditingAllowNonHostsToAddParticipants = shouldAllowEditingAllowNonHostsToAddParticipants
        self.shouldAllowEditingMeetingDescription = shouldAllowEditingMeetingDescription
        self.completion = completion
    }
    
    func updateMeetingLinkEnabled() async {
        updateMeetingLinkEnabled_calledTimes += 1
    }
    
    func submit(meeting: ScheduleMeetingProxyEntity) async throws -> ScheduleMeetingViewConfigurationCompletion {
        completion
    }
    
    var trackingEvents: ScheduleMeetingViewModel.TrackingEvents {
        .init(
            screenEvent: Event(eventName: "screenEvent"),
            meetingLinkEnabled: Event(eventName: "meetingLinkEnabled")
        )
    }
}
