import MEGADomain

struct ScheduleMeetingCreationFrequencyOption {
    let name: String
    let frequency: ScheduledMeetingRulesEntity.Frequency
    let intervalOption: [Int]
    let localizedString: (Int) -> String
    
    func createRules(usingInterval interval: Int, startDate: Date) -> ScheduledMeetingRulesEntity {
        var rules = ScheduledMeetingRulesEntity(frequency: frequency)
        rules.interval = interval
        rules.updateDayList(usingStartDate: startDate)
        return rules
    }
}

extension ScheduleMeetingCreationFrequencyOption: Equatable {
    static func == (lhs: ScheduleMeetingCreationFrequencyOption, rhs: ScheduleMeetingCreationFrequencyOption) -> Bool {
        lhs.frequency == rhs.frequency
    }
}

extension ScheduleMeetingCreationFrequencyOption {
    static let daily = ScheduleMeetingCreationFrequencyOption(
        name: Strings.Localizable.Meetings.ScheduleMeeting.Create.Daily.optionTitle,
        frequency: .daily,
        intervalOption: Array(1...99),
        localizedString: { Strings.Localizable.Meetings.Scheduled.Create.Daily.interval($0) }
    )
    
    static let weekly = ScheduleMeetingCreationFrequencyOption(
        name: Strings.Localizable.Meetings.ScheduleMeeting.Create.Weekly.optionTitle,
        frequency: .weekly,
        intervalOption: Array(1...52),
        localizedString: { Strings.Localizable.Meetings.Scheduled.Create.Weekly.interval($0) }
    )
    
    static let monthly = ScheduleMeetingCreationFrequencyOption(
        name: Strings.Localizable.Meetings.ScheduleMeeting.Create.Monthly.optionTitle,
        frequency: .monthly,
        intervalOption: Array(1...12),
        localizedString: { Strings.Localizable.Meetings.Scheduled.Create.Monthly.interval($0) }
    
    )
    
    static let all = [daily, weekly, monthly]
}
