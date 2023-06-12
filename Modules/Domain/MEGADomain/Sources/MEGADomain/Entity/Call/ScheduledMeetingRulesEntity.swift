import Foundation

public struct ScheduledMeetingRulesEntity: Sendable, Equatable {
    public enum Frequency: Sendable {
        case invalid
        case daily
        case weekly
        case monthly
    }
    
    public var frequency: Frequency
    public var interval: Int
    public var until: Date?
    public var monthDayList: [Int]?
    public var weekDayList: [Int]?
    public var monthWeekDayList: [[Int]]?
    
    public init(
        frequency: Frequency,
        interval: Int = 0,
        until: Date? = nil,
        monthDayList: [Int]? = nil,
        weekDayList: [Int]? = nil,
        monthWeekDayList: [[Int]]? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.until = until
        self.monthDayList = monthDayList
        self.weekDayList = weekDayList
        self.monthWeekDayList = monthWeekDayList
    }
}
