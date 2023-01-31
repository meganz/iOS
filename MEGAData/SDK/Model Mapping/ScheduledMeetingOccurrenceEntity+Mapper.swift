import MEGADomain

extension MEGAChatScheduledMeetingOccurrence {
    func toScheduledMeetingOccurrenceEntity() -> ScheduledMeetingOccurrenceEntity {
        ScheduledMeetingOccurrenceEntity(with: self)
    }
}

fileprivate extension ScheduledMeetingOccurrenceEntity {
    init(with scheduledMeetingOccurrence: MEGAChatScheduledMeetingOccurrence) {
        self.init(
            cancelled: scheduledMeetingOccurrence.isCancelled,
            scheduledId: scheduledMeetingOccurrence.scheduledId,
            timezone: scheduledMeetingOccurrence.timezone,
            startDate: Date(timeIntervalSince1970: TimeInterval(scheduledMeetingOccurrence.startDateTime)), endDate: Date(timeIntervalSince1970: TimeInterval(scheduledMeetingOccurrence.endDateTime))
        )
    }
}
