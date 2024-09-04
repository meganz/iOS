import Foundation

public struct ScheduleMeetingProxyEntity: Sendable {
    public let title: String
    public let description: String
    public let participantHandleList: [HandleEntity]
    public let meetingLinkEnabled: Bool
    public let calendarInvite: Bool
    public let waitingRoom: Bool
    public let allowNonHostsToAddParticipantsEnabled: Bool
    public let startDate: Date
    public let endDate: Date
    public let rules: ScheduledMeetingRulesEntity?
    
    public init(
        title: String,
        description: String,
        participantHandleList: [HandleEntity],
        meetingLinkEnabled: Bool,
        calendarInvite: Bool,
        waitingRoom: Bool,
        allowNonHostsToAddParticipantsEnabled: Bool,
        startDate: Date,
        endDate: Date,
        rules: ScheduledMeetingRulesEntity?
    ) {
        self.title = title
        self.description = description
        self.participantHandleList = participantHandleList
        self.calendarInvite = calendarInvite
        self.waitingRoom = waitingRoom
        self.meetingLinkEnabled = meetingLinkEnabled
        self.allowNonHostsToAddParticipantsEnabled = allowNonHostsToAddParticipantsEnabled
        self.startDate = startDate
        self.endDate = endDate
        self.rules = rules
    }
}
