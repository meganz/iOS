import MEGADomain

extension MEGAChatScheduledMeeting {
    func toScheduledMeetingEntity() -> ScheduledMeetingEntity {
        ScheduledMeetingEntity(with: self)
    }
}

fileprivate extension ScheduledMeetingEntity {
    init(with scheduledMeeting: MEGAChatScheduledMeeting) {
        self.init(
            cancelled: scheduledMeeting.isCancelled,
            new: scheduledMeeting.isNew,
            deleted: scheduledMeeting.isDeleted,
            chatId: scheduledMeeting.chatId,
            scheduledId: scheduledMeeting.scheduledId,
            parentScheduledId: scheduledMeeting.parentScheduledId,
            organizerUserId: scheduledMeeting.organizerUserId,
            timezone: scheduledMeeting.timezone,
            startDate: Date(timeIntervalSince1970: TimeInterval(scheduledMeeting.startDateTime)),
            endDate: Date(timeIntervalSince1970: TimeInterval(scheduledMeeting.endDateTime)),
            title: scheduledMeeting.title,
            description: scheduledMeeting.description,
            attributes: scheduledMeeting.attributes,
            overrides: Date(timeIntervalSince1970: TimeInterval(scheduledMeeting.overrides)),
            rules: ScheduledMeetingRulesEntity(with: scheduledMeeting.rules)
        )
    }
}
