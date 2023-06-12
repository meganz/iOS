import SwiftUI
import MEGADomain

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
            if weekDaysList.count == 1 {
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
        
        if monthDayList.count == 1, let ordinalDay = ordinalString(for: monthDayList[0]) {
            footerNote = Strings.Localizable.Meetings.Scheduled.Create.Monthly.SingleDay.footerNote(rules.interval)
            footerNote = footerNote.replacingOccurrences(of: "[ordinalDay]", with: ordinalDay)
        } else if monthDayList.count > 1 {
            var monthDays = monthDayList.sorted()
            let lastDay = monthDays.removeLast()
            let ordinalMonthDays = monthDays.compactMap(ordinalString(for:)).joined(separator: ", ")
            let ordinalLastDay = ordinalString(for: lastDay)
            footerNote = Strings.Localizable.Meetings.Scheduled.Create.Monthly.MultipleDays.footerNote(rules.interval)
            footerNote = footerNote.replacingOccurrences(of: "[ordinalDays]", with: ordinalMonthDays)
            footerNote = footerNote.replacingOccurrences(of: "[ordinalLastDay]", with: ordinalLastDay ?? "")
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
        footerNote = footerNote.replacingOccurrences(of: "[weekNumber]", with: ordinalString(for: weekNumber) ?? "")
        return footerNote.replacingOccurrences(of: "[weekDayName]", with: weekDaysInformation.symbols[weekDayInt - 1])
    }
    
    private func ordinalString(for day: Int) -> String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .ordinal
        return numberFormatter.string(from: NSNumber(value: day))
    }
}
