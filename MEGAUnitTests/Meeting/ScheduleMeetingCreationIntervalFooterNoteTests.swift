import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class ScheduleMeetingCreationIntervalFooterNoteTests: XCTestCase {
    
    func testString_withFrequencyInvalid_shouldMatch() throws {
        try assert(
            withFrequency: .invalid,
            interval: 1,
            matchingString: ""
        )
    }
    
    func testString_withFrequencyDailyWithIntervalAsOne_shouldMatch() throws {
        try assertDaily(withInterval: 1)
    }
    
    func testString_withFrequencyDailyWithIntervalOtherThanOne_shouldMatch() throws {
        try assertDaily(withInterval: 3)
    }
    
    func testString_withFrequencyWeeklyWithIntervalAsOne_shouldMatch() throws {
        try assertWeeklyWithSingleDaySelected(interval: 1)
    }
    
    func testString_withFrequencyWeeklyWithIntervalOtherThanOne_shouldMatch() throws {
        try assertWeeklyWithSingleDaySelected(interval: 3)
    }
    
    func testString_withFrequencyWeeklyWithIntervalAsOneAndMultipleDaysSelected_shouldMatch() throws {
        try assertWeeklyWithMultipleDaysSelected(interval: 1)
    }
    
    func testString_withFrequencyWeeklyWithIntervalOtherThanOneAndMultipleDaysSelected_shouldMatch() throws {
        try assertWeeklyWithMultipleDaysSelected(interval: 3)
    }
    
    func testString_withFrequencyMonthlyWithIntervalAsOne_shouldMatch() throws {
        try assertMonthlyFrequencyWithSingleDaySelected(interval: 1)
    }
    
    func testString_withFrequencyMonthlyWithIntervalOtherThanOne_shouldMatch() throws {
        try assertMonthlyFrequencyWithSingleDaySelected(interval: 3)
    }
    
    func testString_withFrequencyMonthlyWithIntervalAsOneAndMultipleDaysSelected_shouldMatch() throws {
        try assertMonthlyFrequencyWithMultipleDaysSelected(interval: 1)
    }
    
    func testString_withFrequencyMonthlyWithIntervalOtherThanOneAndMultipleDaysSelected_shouldMatch() throws {
        try assertMonthlyFrequencyWithMultipleDaysSelected(interval: 3)
    }

    func testString_withFrequencyMonthlyWithIntervalOneWeekNumberAndDaySelected_shouldMatch() throws {
        try assertMonthlyFrequencyWithWeekNumberAndDaySelected(interval: 1)
    }
    
    func testString_withFrequencyMonthlyWithIntervalOtherThanOneWeekNumberAndDaySelected_shouldMatch() throws {
        try assertMonthlyFrequencyWithWeekNumberAndDaySelected(interval: 3)
    }
    
    // MARK: - Private methods
    
    private func assertDaily(withInterval interval: Int) throws {
        try assert(
            withFrequency: .daily,
            interval: interval,
            matchingString: Strings.Localizable.Meetings.Scheduled.Create.Daily.footerNote(interval)
        )
    }
    
    private func assertWeeklyWithSingleDaySelected(interval: Int) throws {
        try assert(
            withFrequency: .weekly,
            interval: interval,
            matchingString: weekDayFooterNote(forInterval: interval)
        )
    }
    
    private func assertWeeklyWithMultipleDaysSelected(interval: Int) throws {
        let selectedDays = [1, 2]
        var rules = try makeRules(withFrequency: .weekly, interval: interval)
        rules.weekDayList = selectedDays
        try assert(
            rules: rules,
            matchingString: weekDayFooterNote(forInterval: interval, selectedDays: selectedDays)
        )
    }
    
    private func assertMonthlyFrequencyWithSingleDaySelected(interval: Int) throws {
        try assert(
            withFrequency: .monthly,
            interval: interval,
            matchingString: try monthlyFooterNote(forInterval: interval)
        )
    }
    
    private func assertMonthlyFrequencyWithMultipleDaysSelected(interval: Int) throws {
        let selectedDays = [1, 2]
        var rules = try makeRules(withFrequency: .monthly, interval: interval)
        rules.monthDayList = selectedDays
        try assert(
            rules: rules,
            matchingString: try monthlyFooterNote(forInterval: interval, selectedDays: selectedDays)
        )
    }
    
    private func assertMonthlyFrequencyWithWeekNumberAndDaySelected(interval: Int) throws {
        let selectedWeekNumberAndWeekDay = [[1, 2]]
        var rules = try makeRules(withFrequency: .monthly, interval: interval)
        rules.monthDayList = nil
        rules.monthWeekDayList = selectedWeekNumberAndWeekDay
        try assert(
            rules: rules,
            matchingString: try monthlyFooterNote(forInterval: interval, selectedWeekNumberAndWeekDay: selectedWeekNumberAndWeekDay)
        )
    }
    
    private func monthlyFooterNote(forInterval interval: Int) throws -> String {
        let footerNote = Strings.Localizable.Meetings.Scheduled.Create.Monthly.SingleDay.footerNote(interval)
        return footerNote.replacingOccurrences(of: "[ordinalDay]", with: try XCTUnwrap(ordinalString(for: 12)))
    }
    
    private func monthlyFooterNote(forInterval interval: Int, selectedDays: [Int]) throws -> String {
        var footerNote = Strings.Localizable.Meetings.Scheduled.Create.Monthly.MultipleDays.footerNote(interval)
        footerNote = footerNote.replacingOccurrences(
            of: "[ordinalDays]",
            with: try XCTUnwrap(ordinalString(for: selectedDays[0]))
        )
        return footerNote.replacingOccurrences(
            of: "[ordinalLastDay]",
            with: try XCTUnwrap(ordinalString(for: selectedDays[1]))
        )
    }
    
    private func monthlyFooterNote(forInterval interval: Int, selectedWeekNumberAndWeekDay: [[Int]]) throws -> String {
        let weekNumber = try XCTUnwrap(selectedWeekNumberAndWeekDay.first?.first)
        let weekDay = try XCTUnwrap(selectedWeekNumberAndWeekDay.first?.last)
        
        var footerNote = Strings.Localizable.Meetings.Scheduled.Create.Monthly.WeekNumberAndWeekDay.footerNote(interval)
        footerNote = footerNote.replacingOccurrences(of: "[weekNumber]", with: try XCTUnwrap(ordinalString(for: weekNumber)))
        return footerNote.replacingOccurrences(of: "[weekDayName]", with: WeekDaysInformation().symbols[weekDay - 1])
    }
    
    private func weekDayFooterNote(forInterval interval: Int) -> String {
        let footerNote = Strings.Localizable.Meetings.Scheduled.Create.Weekly.SingleDay.footerNote(interval)
        return footerNote.replacingOccurrences(of: "[weekDayName]", with: WeekDaysInformation().symbols[0])
    }
    
    private func weekDayFooterNote(
        forInterval interval: Int,
        selectedDays: [Int]
    ) -> String {
        var footerNote = Strings.Localizable.Meetings.Scheduled.Create.Weekly.MultipleDays.footerNote(interval)
        footerNote = footerNote.replacingOccurrences(
            of: "[weekDayNames]",
            with: WeekDaysInformation().symbols[selectedDays[0] - 1]
        
        )
        return footerNote.replacingOccurrences(
            of: "[lastWeekDayName]",
            with: WeekDaysInformation().symbols[selectedDays[1] - 1]
        )
    }
    
    private func assert(
        withFrequency frequency: ScheduledMeetingRulesEntity.Frequency = .invalid,
        interval: Int = 1,
        rules: ScheduledMeetingRulesEntity? = nil,
        matchingString: String
    ) throws {
        var rules = rules
        
        if rules == nil {
            rules = try makeRules(withFrequency: frequency, interval: interval)
        }
        
        let footerNote = ScheduleMeetingCreationIntervalFooterNote(rules: try XCTUnwrap(rules))
        XCTAssertEqual(footerNote.string, matchingString)
    }
    
    private func makeRules(
        withFrequency frequency: ScheduledMeetingRulesEntity.Frequency,
        interval: Int
    ) throws -> ScheduledMeetingRulesEntity {
        var rules = ScheduledMeetingRulesEntity(frequency: frequency, interval: interval)
        let startDate = try XCTUnwrap(sampleDate())
        rules.updateDayList(usingStartDate: startDate)
        return rules
    }
    
    private func sampleDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.date(from: "12/06/2023")
    }
    
    private func ordinalString(for day: Int) -> String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .ordinal
        return numberFormatter.string(from: NSNumber(value: day))
    }
}
