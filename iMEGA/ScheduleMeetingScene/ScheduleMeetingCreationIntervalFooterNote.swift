import MEGADomain
import MEGAL10n
import SwiftUI

struct ScheduleMeetingCreationIntervalFooterNote {
    let rules: ScheduledMeetingRulesEntity
    let weekDaysInformation = WeekDaysInformation()
    
    var string: String {
        switch rules.frequency {
        case .daily:
            return Strings.Localizable.Meetings.Scheduled.Create.Daily.footerNote(rules.interval)
        case .weekly:
            return weeklyFooterNote()
        case .monthly:
            return monthlyFooterNote()
        case .invalid:
            return ""
        }
    }
    
    private func weeklyFooterNote() -> String {
        var footerNote = ""
        
        if let weekDaysList = rules.weekDayList {
            if Set(weekDaysList) == Set(1...7) && rules.interval == 1 {
                footerNote = Strings.Localizable.Meetings.Scheduled.Create.Weekly.EveryDay.footerNote
            } else if weekDaysList.count == 1 {
                footerNote = weeklyFooterNote(withWeekDayInt: weekDaysList[0])
            } else if weekDaysList.count > 1 {
                footerNote = weeklyFooterNote(withWeekDaysList: weekDaysList)
            }
        }
        
        return footerNote
    }
    
    private func weeklyFooterNote(withWeekDayInt weekDayInt: Int) -> String {
        let footerNote = Strings.Localizable.Meetings.Scheduled.Create.Weekly.SingleDay.footerNote(rules.interval)
        return footerNote.replacingOccurrences(of: "[weekDayName]", with: weekDaysInformation.symbols[weekDayInt - 1])
    }
    
    private func weeklyFooterNote(withWeekDaysList weekDaysList: [Int]) -> String {
        var weekDayNames = weekDaysList.sorted().map { weekDaysInformation.symbols[$0 - 1] }
        let lastWeekDayName = weekDayNames.removeLast()
        let weekDayNamesString = weekDayNames.joined(separator: ", ")
        
        var footerNote = Strings.Localizable.Meetings.Scheduled.Create.Weekly.MultipleDays.footerNote(rules.interval)
        footerNote = footerNote.replacingOccurrences(of: "[weekDayNames]", with: weekDayNamesString)
        return footerNote.replacingOccurrences(of: "[lastWeekDayName]", with: lastWeekDayName)
    }
    
    private func monthlyFooterNote() -> String {
        var footerNote = ""
        
        if let monthDayList = rules.monthDayList {
            footerNote = monthlyFooterNote(withMonthDayList: monthDayList)
        } else if let monthWeekDayList = rules.monthWeekDayList {
            footerNote = monthlyFooterNote(withMonthWeekDayList: monthWeekDayList)
        }
        
        return footerNote
    }
    
    private func monthlyFooterNote(withMonthDayList monthDayList: [Int]) -> String {
        var footerNote = ""
        
        if monthDayList.count == 1, let cardinalDay = monthDayList[0].cardinal {
            footerNote = Strings.Localizable.Meetings.Scheduled.Create.Monthly.SingleDayCardinal.footerNote(rules.interval)
            footerNote = footerNote.replacingOccurrences(of: "[cardinalDay]", with: cardinalDay)
        } else if monthDayList.count > 1 {
            var monthDays = monthDayList.sorted()
            let lastDay = monthDays.removeLast()
            let cardinalMonthDays = monthDays.compactMap(\.cardinal).joined(separator: ", ")
            let cardinalLastDay = lastDay.cardinal
            footerNote = Strings.Localizable.Meetings.Scheduled.Create.Monthly.MultipleDaysCardinal.footerNote(rules.interval)
            footerNote = footerNote.replacingOccurrences(of: "[cardinalDays]", with: cardinalMonthDays)
            footerNote = footerNote.replacingOccurrences(of: "[cardinalLastDay]", with: cardinalLastDay ?? "")
        }
        
        return footerNote
    }
    
    private func monthlyFooterNote(withMonthWeekDayList monthWeekDayList: [[Int]]) -> String {
        guard let monthWeekDay = monthWeekDayList.first,
              monthWeekDay.count == 2,
              let weekNumber = monthWeekDay.first,
              let weekDayInt = monthWeekDay.last else {
            return ""
        }

        var footerNote = Strings.Localizable.Meetings.Scheduled.Create.Monthly.WeekNumberAndWeekDay.footerNote(rules.interval)
        footerNote = footerNote.replacingOccurrences(of: "[weekNumber]", with: WeekNumberInformation.word(for: weekNumber) ?? "")
        return footerNote.replacingOccurrences(of: "[weekDayName]", with: weekDaysInformation.symbols[weekDayInt - 1])
    }
}
