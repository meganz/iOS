import MEGADomain

extension MEGAChatScheduledMeeting {
    func toScheduledMeetingEntity() -> ScheduledMeetingEntity {
        ScheduledMeetingEntity(with: self)
    }
}

fileprivate extension ScheduledMeetingEntity {
    init(with scheduledMeeting: MEGAChatScheduledMeeting) {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
        
        self.init(
            cancelled: scheduledMeeting.isCancelled,
            new: scheduledMeeting.isNew,
            deleted: scheduledMeeting.isDeleted,
            chatId: scheduledMeeting.chatId,
            scheduledId: scheduledMeeting.scheduledId,
            parentScheduledId: scheduledMeeting.parentScheduledId,
            organizerUserId: scheduledMeeting.organizerUserId,
            timezone: scheduledMeeting.timezone,
            startDate: dateFormatter.date(from: scheduledMeeting.startDateTime) ?? Date(timeIntervalSince1970: 0),
            endDate: dateFormatter.date(from: scheduledMeeting.endDateTime) ?? Date(timeIntervalSince1970: 0),
            title: scheduledMeeting.title,
            description: scheduledMeeting.description,
            attributes: scheduledMeeting.attributes,
            overrides: scheduledMeeting.overrides
        )
    }
}
