import MEGADomain
import Foundation

public extension ScheduledMeetingOccurrenceEntity {
    init(
        cancelled: Bool = false,
        scheduledId: ChatIdEntity = .invalid,
        parentScheduledId: ChatIdEntity = .invalid,
        overrides: ChatIdEntity = .invalid,
        timezone: String = "",
        startDate: Date = Date(),
        endDate: Date = Date(),
        isTesting: Bool = true
    ) {
        self.init(
            cancelled: cancelled,
            scheduledId: scheduledId,
            parentScheduledId: parentScheduledId,
            overrides: overrides,
            timezone: timezone,
            startDate: startDate,
            endDate: endDate
        )
    }
}
