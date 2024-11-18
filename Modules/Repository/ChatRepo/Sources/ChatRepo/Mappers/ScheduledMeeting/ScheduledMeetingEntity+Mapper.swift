import MEGAChatSdk
import MEGADomain

public extension MEGAChatScheduledMeeting {
    func toScheduledMeetingEntity() -> ScheduledMeetingEntity? {
        ScheduledMeetingEntity(with: self)
    }
}

fileprivate extension ScheduledMeetingEntity {
    init(with scheduledMeeting: MEGAChatScheduledMeeting) {
        
        let flagsEntity: ScheduledMeetingFlagsEntity
        if let flags = scheduledMeeting.flags {
            flagsEntity = ScheduledMeetingFlagsEntity(with: flags)
        } else {
            flagsEntity = ScheduledMeetingFlagsEntity(emailsEnabled: false)
        }
        
        let rulesEntity: ScheduledMeetingRulesEntity
        if let rules = scheduledMeeting.rules {
            rulesEntity = ScheduledMeetingRulesEntity(with: rules)
        } else {
            rulesEntity = ScheduledMeetingRulesEntity(
                frequency: .invalid,
                interval: 0,
                until: nil,
                monthDayList: nil,
                weekDayList: nil,
                monthWeekDayList: nil
            )
        }
        
        self.init(
            cancelled: scheduledMeeting.isCancelled,
            new: scheduledMeeting.isNew,
            deleted: scheduledMeeting.isDeleted,
            chatId: scheduledMeeting.chatId,
            scheduledId: scheduledMeeting.scheduledId,
            parentScheduledId: scheduledMeeting.parentScheduledId,
            organizerUserId: scheduledMeeting.organizerUserId,
            timezone: scheduledMeeting.timezone ?? "",
            startDate: Date(timeIntervalSince1970: TimeInterval(scheduledMeeting.startDateTime)),
            endDate: Date(timeIntervalSince1970: TimeInterval(scheduledMeeting.endDateTime)),
            title: scheduledMeeting.title ?? "",
            description: scheduledMeeting.description ?? "",
            attributes: scheduledMeeting.attributes ?? "",
            overrides: Date(timeIntervalSince1970: TimeInterval(scheduledMeeting.overrides)),
            flags: flagsEntity,
            rules: rulesEntity
        )
    }
}
