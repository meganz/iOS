import MEGAL10n

enum WeekNumberInformation {
    private static let weekNumbers = [
        Strings.Localizable.Meetings.ScheduleMeeting.Create.Monthly.WeekNumber.first,
        Strings.Localizable.Meetings.ScheduleMeeting.Create.Monthly.WeekNumber.second,
        Strings.Localizable.Meetings.ScheduleMeeting.Create.Monthly.WeekNumber.third,
        Strings.Localizable.Meetings.ScheduleMeeting.Create.Monthly.WeekNumber.fourth,
        Strings.Localizable.Meetings.ScheduleMeeting.Create.Monthly.WeekNumber.fifth
    ]
    
    static func word(for number: Int) -> String? {
        weekNumbers[safe: number - 1]
    }
}
