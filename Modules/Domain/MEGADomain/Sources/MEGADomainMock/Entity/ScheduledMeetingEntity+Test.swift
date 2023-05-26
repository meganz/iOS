import MEGADomain
import Foundation

public extension ScheduledMeetingEntity {
    init(
        cancelled: Bool = false,
        new: Bool = true,
        deleted: Bool = false,
        chatId: ChatIdEntity = .invalid,
        scheduledId: ChatIdEntity = .invalid,
        parentScheduledId: ChatIdEntity = .invalid,
        organizerUserId: ChatIdEntity = .invalid,
        timezone: String = "",
        startDate: Date = Date(),
        endDate: Date = Date(timeIntervalSinceNow: 3600),
        title: String = "",
        description: String = "",
        attributes: String = "",
        overrides: Date = Date(),
        rules: ScheduledMeetingRulesEntity = ScheduledMeetingRulesEntity(),
        isTesting: Bool = true
    ) {
        self.init(
            cancelled: cancelled,
            new: new,
            deleted: deleted,
            chatId: chatId,
            scheduledId: scheduledId,
            parentScheduledId: parentScheduledId,
            organizerUserId: organizerUserId,
            timezone: timezone,
            startDate: startDate,
            endDate: endDate,
            title: title,
            description: description,
            attributes: attributes,
            overrides: overrides,
            rules: rules
        )
    }
    
}
