import XCTest
@testable import MEGA
import MEGADomain

final class ScheduleMeetingCreationRecurrenceOptionTests: XCTestCase {
    func testScheduleMeetingCreationRecurrenceOptionNever_withInvalidFrequency_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .invalid)
        let recurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules)
        XCTAssertTrue(recurrenceOption == .never)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionDaily_withDailyFrequencyAndSevenDaysWeekList_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: [1, 2, 3, 4, 5, 6, 7])
        let recurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules)
        XCTAssertTrue(recurrenceOption == .daily)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withDailyFrequencyAndSixDaysWeekList_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: [1, 2, 3, 4, 5, 6])
        let recurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules)
        XCTAssertTrue(recurrenceOption == .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withDailyFrequencyAndNoWeekList_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily)
        let recurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules)
        XCTAssertTrue(recurrenceOption == .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withDailyFrequencyAndEmptyWeekList_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: [])
        let recurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules)
        XCTAssertTrue(recurrenceOption == .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withDailyFrequencyAndOneDayInTheWeekList_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: [1])
        let recurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules)
        XCTAssertTrue(recurrenceOption == .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionWeekly_withWeeklyFrequencyAndOneDayInTheWeekList_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: [1])
        let recurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules)
        XCTAssertTrue(recurrenceOption == .weekly)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withWeeklyFrequencyAndNoDaysInTheWeekList_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .weekly)
        let recurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules)
        XCTAssertTrue(recurrenceOption == .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withWeeklyFrequencyAndEmptyWeekList_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: [])
        let recurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules)
        XCTAssertTrue(recurrenceOption == .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionMonthly_withMonthlyFrequencyAndAMonthInTheMonthDayList_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [1])
        let recurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules)
        XCTAssertTrue(recurrenceOption == .monthly)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withMonthlyFrequencyAndTwoMonthsInTheMonthDayList_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [1, 2])
        let recurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules)
        XCTAssertTrue(recurrenceOption == .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withMonthlyFrequencyAndNoMonthsInTheMonthDayList_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly)
        let recurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules)
        XCTAssertTrue(recurrenceOption == .custom)
    }
    
    func testScheduleMeetingCreationRecurrenceOptionCustom_withMonthlyFrequencyAndEmptyMonthDayList_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [])
        let recurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules)
        XCTAssertTrue(recurrenceOption == .custom)
    }
}
