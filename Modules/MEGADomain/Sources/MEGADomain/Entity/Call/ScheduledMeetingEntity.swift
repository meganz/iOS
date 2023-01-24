import Foundation

public struct ScheduledMeetingEntity {
    public let cancelled: Bool
    public let new: Bool
    public let deleted: Bool
    public let chatId: ChatIdEntity
    public let scheduledId: ChatIdEntity
    public let parentScheduledId: ChatIdEntity
    public let organizerUserId: ChatIdEntity
    public let timezone: String
    public let startDate: Date
    public let endDate: Date
    public let title: String
    public let description: String
    public let attributes: String
    public let overrides: Date
    public let rules: ScheduledMeetingRulesEntity
    
    public init(
        cancelled: Bool,
        new: Bool,
        deleted: Bool,
        chatId: ChatIdEntity,
        scheduledId: ChatIdEntity,
        parentScheduledId: ChatIdEntity,
        organizerUserId: ChatIdEntity,
        timezone: String,
        startDate: Date,
        endDate: Date,
        title: String,
        description: String,
        attributes: String,
        overrides: Date,
        rules: ScheduledMeetingRulesEntity
    ) {
        self.cancelled = cancelled
        self.new = new
        self.deleted = deleted
        self.chatId = chatId
        self.scheduledId = scheduledId
        self.parentScheduledId = parentScheduledId
        self.organizerUserId = organizerUserId
        self.timezone = timezone
        self.startDate = startDate
        self.endDate = endDate
        self.title = title
        self.description = description
        self.attributes = attributes
        self.overrides = overrides
        self.rules = rules
    }
}
