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
    
    init(rules: ScheduledMeetingRulesEntity) {
        switch rules.frequency {
        case .invalid:
            self = .never
        case .daily:
            self = rules.weekDayList == Array(1...7) ? .daily : .custom
        case .weekly:
            self = rules.weekDayList?.count == 1 ? .weekly : .custom
        case .monthly:
            self = rules.monthDayList?.count == 1 ? .monthly : .custom
        }
    }
}
