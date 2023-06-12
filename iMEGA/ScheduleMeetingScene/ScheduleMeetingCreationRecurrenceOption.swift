import MEGADomain

enum ScheduleMeetingCreationRecurrenceOption: Identifiable {
    var id: Self { self }
    
    case never
    case daily
    case weekly
    case monthly
    case custom
    
    var localizedString: String {
        switch self {
        case .never:
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.RecurrenceOptionScreen.never
        case .daily:
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.RecurrenceOptionScreen.daily
        case .weekly:
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.RecurrenceOptionScreen.weekly
        case .monthly:
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.RecurrenceOptionScreen.monthly
        case .custom:
            return Strings.Localizable.Meetings.ScheduleMeeting.Create.RecurrenceOptionScreen.custom
        }
    }
    
    init(rules: ScheduledMeetingRulesEntity, startDate: Date) {
        guard rules.frequency != .invalid else {
            self = .never
            return
        }
        
        guard rules.interval == 1 else {
            self = .custom
            return
        }

        if rules.frequency == .daily, rules.weekDayList == Array(1...7) {
            self = .daily
        } else if rules.frequency == .weekly,
                  let weekDayList = rules.weekDayList,
                  weekDayList.count == 1,
                  (weekDayList[0] - 1) == WeekDaysInformation().weekDay(forStartDate: startDate) {
            self = .weekly
        } else if rules.frequency == .monthly,
                  rules.monthDayList?.count == 1,
                  Calendar.current.dateComponents([.day], from: startDate).day == rules.monthDayList?.first {
            self = .monthly
        } else {
            self = .custom
        }
    }
}
