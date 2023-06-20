import XCTest
@testable import MEGA
import MEGADomain

final class ScheduleMeetingCreationRecurrenceOptionTests: XCTestCase {
    func testScheduleMeetingCreationRecurrenceOptionNever_withInvalidFrequency_shouldMatch() throws {
        let rules = ScheduledMeetingRulesEntity(frequency: .invalid)
        try assertRecurrenceOption(withRules: rules, expectedOption: .never)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionDaily_withDailyFrequencyAndSevenDaysWeekList_shouldMatch() throws {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, interval: 1, weekDayList: Array(1...7))
        try assertRecurrenceOption(withRules: rules, expectedOption: .daily)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withDailyFrequencyAndSixDaysWeekList_shouldMatch() throws {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...6))
        try assertRecurrenceOption(withRules: rules, expectedOption: .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withDailyFrequencyAndNoWeekList_shouldMatch() throws {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily)
        try assertRecurrenceOption(withRules: rules, expectedOption: .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withDailyFrequencyAndEmptyWeekList_shouldMatch() throws {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: [])
        try assertRecurrenceOption(withRules: rules, expectedOption: .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withDailyFrequencyAndOneDayInTheWeekList_shouldMatch() throws {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: [1])
        try assertRecurrenceOption(withRules: rules, expectedOption: .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionWeekly_withWeeklyFrequencyAndOneDayInTheWeekList_shouldMatch() throws {
        let rules = ScheduledMeetingRulesEntity(frequency: .weekly, interval: 1, weekDayList: [3])
        try assertRecurrenceOption(withRules: rules, expectedOption: .weekly)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withWeeklyFrequencyAndNoDaysInTheWeekList_shouldMatch() throws {
        let rules = ScheduledMeetingRulesEntity(frequency: .weekly)
        try assertRecurrenceOption(withRules: rules, expectedOption: .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withWeeklyFrequencyAndEmptyWeekList_shouldMatch() throws {
        let rules = ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: [])
        try assertRecurrenceOption(withRules: rules, expectedOption: .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionMonthly_withMonthlyFrequencyAndAMonthInTheMonthDayList_shouldMatch() throws {
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, interval: 1, monthDayList: [14])
        try assertRecurrenceOption(withRules: rules, expectedOption: .monthly)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withMonthlyFrequencyAndTwoMonthsInTheMonthDayList_shouldMatch() throws {
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [1, 2])
        try assertRecurrenceOption(withRules: rules, expectedOption: .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withMonthlyFrequencyAndNoMonthsInTheMonthDayList_shouldMatch() throws {
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly)
        try assertRecurrenceOption(withRules: rules, expectedOption: .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withMonthlyFrequencyAndEmptyMonthDayList_shouldMatch() throws {
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [])
        try assertRecurrenceOption(withRules: rules, expectedOption: .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withMonthlyFrequencyAndMonthWeekDayList_shouldMatch() throws {
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthWeekDayList: [[2, 3]])
        try assertRecurrenceOption(withRules: rules, expectedOption: .custom)
    }
    
    // MARK: - Private methods.
    
    private func assertRecurrenceOption(withRules rules: ScheduledMeetingRulesEntity, expectedOption: ScheduleMeetingCreationRecurrenceOption) throws {
        let sampleDate = try XCTUnwrap(sampleDate())
        let recurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules, startDate: sampleDate)
        XCTAssertEqual(recurrenceOption, expectedOption)
    }
    
    private func sampleDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.date(from: "14/06/2023")
    }
}
