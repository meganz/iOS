import Foundation

public struct ScheduledMeetingRulesEntity: Sendable, Equatable {
    public enum Frequency : Sendable {
        case invalid
        case daily
        case weekly
        case monthly
    }
    
    public let frequency: Frequency
    public let interval: Int
    public let until: Date?
    public let monthDayList: [Int]?
    public let weekDayList: [Int]?
    public let monthWeekDayList: [[Int]]?
    
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
