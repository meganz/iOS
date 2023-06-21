import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class ScheduleMeetingSelectedFrequencyDetailsTests: XCTestCase {
    
    func testString_givenFrequencyOptionNever_shouldMatch() throws {
        let frequencyDetails = try makeFrequencyDetails(forFrequency: .invalid)
        XCTAssertEqual(
            frequencyDetails.string,
            Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrenceOption.never
        )
    }
    
    func testString_givenFrequencyOptionDaily_shouldMatch() throws {
        let frequencyDetails = try makeFrequencyDetails(forFrequency: .daily)
        XCTAssertEqual(
            frequencyDetails.string,
            Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrenceOption.daily
        )
    }
    
    func testString_givenFrequencyOptionWeekly_shouldMatch() throws {
        let frequencyDetails = try makeFrequencyDetails(forFrequency: .weekly)
        XCTAssertEqual(
            frequencyDetails.string,
            Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrenceOption.weekly
        )
    }
    
    func testString_givenFrequencyOptionMonthly_shouldMatch() throws {
        let frequencyDetails = try makeFrequencyDetails(forFrequency: .monthly)
        XCTAssertEqual(
            frequencyDetails.string,
            Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrenceOption.monthly
        )
    }
    
    func testString_givenFrequencyOptionCustomDaily_shouldMatch() throws {
        var rules = try makeRules(forFrequency: .daily, interval: 2)
        rules.weekDayList = Array(1...9)
        let frequencyDetails = try makeFrequencyDetails(rules: rules)
        XCTAssertEqual(
            frequencyDetails.string,
            Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrence.Daily.customInterval(2)
        )
    }
    
    func testString_givenFrequencyOptionCustomWeeklyWithIntervalAsOne_shouldMatch() throws {
        try assertCustomWeekly(withInterval: 1)
    }
    
    func testString_givenFrequencyOptionCustomWeeklyWithIntervalMoreThan1_shouldMatch() throws {
        try assertCustomWeekly(withInterval: 3)
    }

    func testString_givenFrequencyOptionCustomMonthlyWithMonthDayListAndIntervalAsOne_shouldMatch() throws {
        try assertCustomMonthlyDayList(withInterval: 1)
    }
    
    func testString_givenFrequencyOptionCustomMonthlyWithMonthDayListAndIntervalOtherThanOne_shouldMatch() throws {
        try assertCustomMonthlyDayList(withInterval: 5)
    }
    
    func testString_givenFrequencyOptionCustomMonthlyWithMonthWeekDayListAndIntervalAsOne_shouldMatch() throws {
        try assertCustomMonthlyWeekDayList(withInterval: 1)
    }
    
    func testString_givenFrequencyOptionCustomMonthlyWithMonthWeekDayListAndIntervalOtherThanOne_shouldMatch() throws {
        try assertCustomMonthlyWeekDayList(withInterval: 7)
    }
    
    func testString_givenFrequencyOptionWeeklyAndAllDaysSelected_shouldMatch() throws {
        var rules = try makeRules(forFrequency: .weekly)
        rules.weekDayList = Array(1...7)
        let frequencyDetails = try makeFrequencyDetails(rules: rules)
        XCTAssertEqual(frequencyDetails.string, Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrence.Weekly.everyDay)
    }

    // MARK: - Private methods
    
    private func assertCustomMonthlyWeekDayList(withInterval interval: Int) throws {
        var rules = try makeRules(forFrequency: .monthly, interval: interval)
        rules.monthDayList = nil
        rules.monthWeekDayList = [[2, 4]]
        let frequencyDetails = try makeFrequencyDetails(rules: rules)
        let expectedString = Strings.Localizable.Meetings.Scheduled.Create.Monthly.WeekNumberAndWeekDay.selectedFrequency(interval)
            .replacingOccurrences(of: "[ordinalNumber]", with: "2nd")
            .replacingOccurrences(of: "[weekDayName]", with: WeekDaysInformation().shortSymbols[3])
        XCTAssertEqual(frequencyDetails.string, expectedString)
    }
    
    private func assertCustomMonthlyDayList(withInterval interval: Int) throws {
        var rules = try makeRules(forFrequency: .monthly, interval: interval)
        rules.monthDayList = [1]
        let frequencyDetails = try makeFrequencyDetails(rules: rules)
        let expectedString = Strings.Localizable.Meetings.Scheduled.Create.Monthly.WeekDay.selectedFrequency(interval)
            .replacingOccurrences(of: "[ordinalNumber]", with: "1st")
        XCTAssertEqual(frequencyDetails.string, expectedString)

    }
    
    private func assertCustomWeekly(withInterval interval: Int) throws {
        var rules = try makeRules(forFrequency: .weekly, interval: interval)
        rules.weekDayList = [4]
        let frequencyDetails = try makeFrequencyDetails(rules: rules)
        let expectedString = Strings.Localizable.Meetings.Scheduled.Create.Weekly.selectedFrequency(interval)
            .replacingOccurrences(of: "[weekDayNames]", with: WeekDaysInformation().shortSymbols[3])
        XCTAssertEqual(frequencyDetails.string, expectedString)
    }
    
    private func makeFrequencyDetails(
        forFrequency frequency: ScheduledMeetingRulesEntity.Frequency? = nil,
        rules: ScheduledMeetingRulesEntity? = nil
    ) throws -> ScheduleMeetingSelectedFrequencyDetails {
        let sampleDate = try XCTUnwrap(sampleDate())
        var rules = rules
        if rules == nil, let frequency {
            rules = try makeRules(forFrequency: frequency)
        }
        let unwrappedRules = try XCTUnwrap(rules)
        return ScheduleMeetingSelectedFrequencyDetails(rules: unwrappedRules, startDate: sampleDate)
    }
    
    private func makeRules(
        forFrequency frequency: ScheduledMeetingRulesEntity.Frequency,
        interval: Int = 1
    ) throws -> ScheduledMeetingRulesEntity {
        let sampleDate = try XCTUnwrap(sampleDate())
        var rules = ScheduledMeetingRulesEntity(frequency: frequency, interval: interval)
        if interval == 1 {
            rules.reset(toFrequency: frequency, usingStartDate: sampleDate)
        }
        return rules
    }
    
    private func sampleDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.date(from: "12/06/2023")
    }
}
