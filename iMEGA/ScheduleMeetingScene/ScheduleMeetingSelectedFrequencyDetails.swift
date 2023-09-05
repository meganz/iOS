import MEGADomain
import MEGAL10n

struct ScheduleMeetingSelectedFrequencyDetails {
    let rules: ScheduledMeetingRulesEntity
    let startDate: Date
    private let weekDaysInformation = WeekDaysInformation()
    
    var string: String {
        switch ScheduleMeetingCreationRecurrenceOption(rules: rules, startDate: startDate) {
        case .never:
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrenceOption.never
        case .daily:
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrenceOption.daily
        case .weekly:
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrenceOption.weekly
        case .monthly:
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrenceOption.monthly
        case .custom:
            return customString()
        }
    }
    
    private func customString() -> String {
        switch rules.frequency {
        case .invalid:
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrenceOption.never
        case .daily:
            return dailyString()
        case .weekly:
            return weeklyString()
        case .monthly:
            return monthlyString()
        }
    }
    
    private func dailyString() -> String {
        Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrence.Daily.customInterval(rules.interval)
    }
    
    private func weeklyString() -> String {
        guard let weekDayList = rules.weekDayList else { return "" }
        guard Set(weekDayList) != Set(1...7) || rules.interval > 1 else {
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrence.Weekly.everyDay
        }
        
        let string = Strings.Localizable.Meetings.Scheduled.Create.Weekly.selectedFrequency(rules.interval)

        var weekDayNames = ""
        if weekDayList.count == 1 {
            weekDayNames = weekDayList
                .first
                .map({ weekDaysInformation.shortSymbols[$0 - 1] }) ?? ""
        } else if weekDayList.count > 1 {
            weekDayNames = weekDayList
                .compactMap { weekDaysInformation.shortSymbols[$0 - 1] }
                .joined(separator: ", ")
        }
        
        return string.replacingOccurrences(of: "[weekDayNames]", with: weekDayNames)
    }
    
    private func monthlyString() -> String {
        if let monthDayList = rules.monthDayList,
           let monthDay = monthDayList.first,
           let cardinalNumber = monthDay.cardinal {
            let string = Strings.Localizable.Meetings.Scheduled.Create.Monthly.WeekDayCardinal.selectedFrequency(rules.interval)
            return string.replacingOccurrences(of: "[cardinalNumber]", with: cardinalNumber)
        } else if let monthWeekDayList = rules.monthWeekDayList {
            guard let weekNumber = monthWeekDayList.first?.first,
                  let weekNumberString = WeekNumberInformation.word(for: weekNumber),
                  let weekDayInt = monthWeekDayList.first?.last else {
                return ""
            }
            
            let weekDayName = weekDaysInformation.shortSymbols[weekDayInt - 1]
            var string = Strings.Localizable.Meetings.Scheduled.Create.Monthly.WeekNumberAndWeekDay.selectedFrequency(rules.interval)
            string = string.replacingOccurrences(of: "[ordinalNumber]", with: weekNumberString)
            return string.replacingOccurrences(of: "[weekDayName]", with: weekDayName)
        }
        
        return ""
    }
}
