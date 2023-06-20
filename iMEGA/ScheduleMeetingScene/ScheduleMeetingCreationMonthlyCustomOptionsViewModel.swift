import MEGADomain
import SwiftUI

final class ScheduleMeetingCreationMonthlyCustomOptionsViewModel: ObservableObject {
    private let weekDaysInformation = WeekDaysInformation()
    
    var weekdaySymbols: [String] {
        weekDaysInformation.symbols
    }
    
    var monthlyCustomOptions: [String] {
        [Strings.Localizable.Meetings.ScheduleMeeting.Create.Monthly.Calendar.headerTitle,
         Strings.Localizable.Meetings.ScheduleMeeting.Create.Monthly.WeekNumberAndWeekDay.headerTitle]
    }
    
    var weekNumbers: [String] {
        [Strings.Localizable.Meetings.ScheduleMeeting.Create.Monthly.WeekNumber.first,
         Strings.Localizable.Meetings.ScheduleMeeting.Create.Monthly.WeekNumber.second,
         Strings.Localizable.Meetings.ScheduleMeeting.Create.Monthly.WeekNumber.third,
         Strings.Localizable.Meetings.ScheduleMeeting.Create.Monthly.WeekNumber.fourth,
         Strings.Localizable.Meetings.ScheduleMeeting.Create.Monthly.WeekNumber.fifth]
    }
    
    var selectedWeekNumber: String? {
        guard let weekIndex = rules.monthWeekDayList?.first?.first else { return nil }
        return weekNumbers[weekIndex - 1]
    }
    
    var selectedWeekSymbol: String? {
        guard let index = rules.monthWeekDayList?.first?.last else {
            return nil
        }
        
        return weekDaysInformation.symbols[index - 1]
    }
    
    var selectedDays: Set<String> {
        Set(rules.monthDayList?.compactMap(String.init) ?? [])
    }
    
    var selectedCustomOption: String {
        rules.monthDayList != nil ? monthlyCustomOptions[0] : monthlyCustomOptions[1]
    }
        
    @Published
    private(set) var rules: ScheduledMeetingRulesEntity
    
    private let startDate: Date

    init(rules: ScheduledMeetingRulesEntity, startDate: Date) {
        self.rules = rules
        self.startDate = startDate
    }
    
    func resetSelection(to selectedOption: String) {
        if selectedOption == monthlyCustomOptions.first {
            guard let day = Calendar.current.dateComponents([.day], from: startDate).day else { return }
            updateSelectedMonthDayList([day])
        } else {
            let weekDay = weekDaysInformation.weekDay(forStartDate: startDate)
            let weekNumber = Calendar.current.component(.weekOfMonth, from: startDate)
            selected(weekNumber: weekNumbers[weekNumber - 1], andWeekDay: weekDaysInformation.symbols[weekDay])
        }
    }
    
    func updateSelectedMonthDayList(_ monthDayList: [Int]?) {
        rules.monthDayList = monthDayList
        rules.monthWeekDayList = nil
    }
    
    func updateMonthWeekDayList(_ monthWeekDayList: [[Int]]?) {
        rules.monthWeekDayList = monthWeekDayList
        rules.monthDayList = nil
    }
    
    func update(interval: Int) {
        rules.interval = interval
    }
    
    func selected(weekNumber: String, andWeekDay weekDay: String) {
        guard let weekNumberIndex = weekNumbers.firstIndex(of: weekNumber),
              let symbolIndex = weekDaysInformation.symbols.firstIndex(of: weekDay) else {
            MEGALogError("index not found for \(weekNumber) and \(weekDay)")
            return
        }
        
        updateMonthWeekDayList([[weekNumberIndex + 1, symbolIndex + 1]])
    }
    
    func calendarFooterNote() -> String? {
        if let monthDayList = rules.monthDayList, Set(monthDayList).intersection([29, 30, 31]).isNotEmpty {
            if monthDayList.contains(29) {
                return Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayTwentyNineSelected.footNote
            } else if monthDayList.contains(30) {
                return Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayThirtySelected.footNote
            } else if monthDayList.contains(31) {
                return Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayThirtyFirstSelected.footNote
            }
        }
        
        return nil
    }
}
