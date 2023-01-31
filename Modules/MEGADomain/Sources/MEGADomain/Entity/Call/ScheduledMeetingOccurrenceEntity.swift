import Foundation

public struct ScheduledMeetingOccurrenceEntity {
    public let cancelled: Bool
    public let scheduledId: ChatIdEntity
    public let timezone: String
    public let startDate: Date
    public let endDate: Date
    
    public init(
        cancelled: Bool,
        scheduledId: ChatIdEntity,
        timezone: String,
        startDate: Date,
        endDate: Date
    ) {
        self.cancelled = cancelled
        self.scheduledId = scheduledId
        self.timezone = timezone
        self.startDate = startDate
        self.endDate = endDate
    }
}
