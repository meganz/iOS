import Foundation

public struct ScheduledMeetingOccurrenceEntity: Hashable, Sendable {
    public var cancelled: Bool
    public let scheduledId: ChatIdEntity
    public let parentScheduledId: ChatIdEntity
    public var overrides: UInt64
    public let timezone: String
    public let startDate: Date
    public let endDate: Date
    
    public init(
        cancelled: Bool,
        scheduledId: ChatIdEntity,
        parentScheduledId: ChatIdEntity,
        overrides: UInt64,
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
