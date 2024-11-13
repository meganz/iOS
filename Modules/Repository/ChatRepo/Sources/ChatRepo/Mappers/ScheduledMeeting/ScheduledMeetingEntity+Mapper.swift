import MEGAChatSdk
import MEGADomain

public extension MEGAChatScheduledMeeting {
    func toScheduledMeetingEntity() -> ScheduledMeetingEntity? {
        ScheduledMeetingEntity(with: self)
    }
}

fileprivate extension ScheduledMeetingEntity {
    init?(with scheduledMeeting: MEGAChatScheduledMeeting) {
        
        guard
            let sdkFlags = scheduledMeeting.flags,
            let sdkRules = scheduledMeeting.rules,
            let title = scheduledMeeting.title,
            let description = scheduledMeeting.description,
            let timezone = scheduledMeeting.timezone,
            let attributes = scheduledMeeting.attributes
        else {
            return nil
        }
        
        self.init(
            cancelled: scheduledMeeting.isCancelled,
            new: scheduledMeeting.isNew,
            deleted: scheduledMeeting.isDeleted,
            chatId: scheduledMeeting.chatId,
            scheduledId: scheduledMeeting.scheduledId,
            parentScheduledId: scheduledMeeting.parentScheduledId,
            organizerUserId: scheduledMeeting.organizerUserId,
            timezone: timezone,
            startDate: Date(timeIntervalSince1970: TimeInterval(scheduledMeeting.startDateTime)),
            endDate: Date(timeIntervalSince1970: TimeInterval(scheduledMeeting.endDateTime)),
            title: title,
            description: description,
            attributes: attributes,
            overrides: Date(timeIntervalSince1970: TimeInterval(scheduledMeeting.overrides)),
            flags: ScheduledMeetingFlagsEntity(with: sdkFlags),
            rules: ScheduledMeetingRulesEntity(with: sdkRules)
        )
    }
}
