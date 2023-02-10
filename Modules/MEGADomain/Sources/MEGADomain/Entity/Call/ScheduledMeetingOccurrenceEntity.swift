import Foundation

public struct ScheduledMeetingOccurrenceEntity: Hashable {
    public let cancelled: Bool
    public let scheduledId: ChatIdEntity
    public let parentScheduledId: ChatIdEntity
    public let overrides: ChatIdEntity
    public let timezone: String
    public let startDate: Date
    public let endDate: Date
    
    public init(
        cancelled: Bool,
        scheduledId: ChatIdEntity,
        parentScheduledId: ChatIdEntity,
        overrides: ChatIdEntity,
        timezone: String,
        startDate: Date,
        endDate: Date
    ) {
        self.cancelled = cancelled
        self.scheduledId = scheduledId
        self.parentScheduledId = parentScheduledId
        self.overrides = overrides
        self.timezone = timezone
        self.startDate = startDate
        self.endDate = endDate
    }
}

