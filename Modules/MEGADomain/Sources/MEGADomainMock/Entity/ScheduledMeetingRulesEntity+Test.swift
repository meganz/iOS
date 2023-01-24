import MEGADomain
import Foundation

public extension ScheduledMeetingRulesEntity {
    init(
        frequency: Frequency = .invalid,
        interval: Int = 0,
        until: Date? = nil,
        monthDayList: [Int]? = nil,
        weekDayList: [Int]? = nil,
        monthWeekDayList: [[Int]]? = nil,
        testing: Bool = true
    ) {
        self.init(
            frequency: frequency,
            interval: interval,
            until: until,
            monthDayList: monthDayList,
            weekDayList: weekDayList,
            monthWeekDayList: monthWeekDayList
        )
    }
}
