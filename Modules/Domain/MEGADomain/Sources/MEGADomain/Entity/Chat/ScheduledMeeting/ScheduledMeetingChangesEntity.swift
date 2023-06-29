import Foundation

public struct ScheduledMeetingChangesEntity {
    public let timezone: String?
    public let startDate: Date?
    public let endDate: Date?
    public let title: String?
    public let description: String?
    public let cancelled: Bool?
    public let rules: ScheduledMeetingRulesEntity?
    
    public init(timezone: String? = nil,
                startDate: Date? = nil,
                endDate: Date? = nil,
                title: String? = nil,
                description: String? = nil,
                cancelled: Bool? = nil,
                rules: ScheduledMeetingRulesEntity? = nil
    ) {
        self.timezone = timezone
        self.startDate = startDate
        self.endDate = endDate
        self.title = title
        self.description = description
        self.cancelled = cancelled
        self.rules = rules
    }
}
