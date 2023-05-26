import Foundation

public struct CreateScheduleMeetingEntity {
    public let title: String
    public let description: String
    public let participants: [UserEntity]
    public let calendarInvite: Bool
    public let openInvite: Bool
    public let startDate: Date
    public let endDate: Date
    public let rules: ScheduledMeetingRulesEntity?
    
    public init(
        title: String,
        description: String,
        participants: [UserEntity],
        calendarInvite: Bool,
        openInvite: Bool,
        startDate: Date,
        endDate: Date,
        rules: ScheduledMeetingRulesEntity?
    ) {
        self.title = title
        self.description = description
        self.participants = participants
        self.calendarInvite = calendarInvite
        self.openInvite = openInvite
        self.startDate = startDate
        self.endDate = endDate
        self.rules = rules
    }
}
