import Foundation

public struct ScheduledMeetingEntity: Sendable {
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
    public let flags: ScheduledMeetingFlagsEntity
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
        flags: ScheduledMeetingFlagsEntity,
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
        self.flags = flags
        self.rules = rules
    }
    
    public var weekday: Weekday? {
        switch self.rules.monthWeekDayList?.first?[1] {
        case 1:
            return .monday
        case 2:
            return .tuesday
        case 3:
            return .wednesday
        case 4:
            return .thursday
        case 5:
            return .friday
        case 6:
            return .saturday
        case 7:
            return .sunday
        default:
            return nil
        }
    }
    
    public var weekOfMonth: WeekOfMonth? {
        switch self.rules.monthWeekDayList?.first?[0] {
        case 1:
            return .first
        case 2:
            return .second
        case 3:
            return .third
        case 4:
            return .fourth
        case 5:
            return .fifth
        default:
            return nil
        }
    }
    
    public enum Weekday {
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday
        case sunday
    }
    
    public enum WeekOfMonth {
        case first
        case second
        case third
        case fourth
        case fifth
    }
}

extension ScheduledMeetingEntity: Hashable {
    public static func == (lhs: ScheduledMeetingEntity, rhs: ScheduledMeetingEntity) -> Bool {
        lhs.scheduledId == rhs.scheduledId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(scheduledId)
    }
}

extension ScheduledMeetingEntity: Identifiable {
    public var id: HandleEntity { scheduledId }
}
