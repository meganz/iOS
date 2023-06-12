import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class ScheduleMeetingCreationFrequencyOptionTests: XCTestCase {
    
    func testName_forAll_shouldMatch() {
        let allOptions: [ScheduleMeetingCreationFrequencyOption] = [.daily, .weekly, .monthly]
        XCTAssertEqual(ScheduleMeetingCreationFrequencyOption.all, allOptions)
    }
    
    func testCreateRules_withIntervalAsOneForDaily_shouldMatch() {
       assertDaily(withInterval: 1)
    }
    
    func testCreateRules_withIntervalMoreThanOneForDaily_shouldMatch() {
        assertDaily(withInterval: 3)
    }
    
    func testCreateRules_withIntervalAsOneForWeekly_shouldMatch() {
       assertWeekly(withInterval: 1)
    }
    
    func testCreateRules_withIntervalMoreThanOneForWeekly_shouldMatch() {
        assertWeekly(withInterval: 3)
    }
    
    func testCreateRules_withIntervalAsOneForMonthly_shouldMatch() {
        assertMonthly(withInterval: 1)
    }
    
    func testCreateRules_withIntervalMoreThanOneForMonthly_shouldMatch() {
        assertMonthly(withInterval: 3)
    }
    
    // MARK: - Private methods.
    private func assertDaily(withInterval interval: Int) {
        let rules = makeRulesAndAssert(withFrequencyOption: .daily, interval: interval)
        XCTAssertEqual(rules.weekDayList, Array(1...7))
    }
    
    private func assertWeekly(withInterval interval: Int) {
        let rules = makeRulesAndAssert(withFrequencyOption: .weekly, interval: interval)
        XCTAssertEqual(rules.weekDayList?.count, 1)
    }
    
    private func makeRulesAndAssert(
        withFrequencyOption frequencyOption: ScheduleMeetingCreationFrequencyOption,
        interval: Int
    ) -> ScheduledMeetingRulesEntity {
        let rules = frequencyOption.createRules(usingInterval: interval)
        XCTAssertEqual(rules.frequency, frequencyOption.frequency)
        XCTAssertEqual(rules.interval, interval)
        return rules
    }
    
    private func assertMonthly(withInterval interval: Int) {
        let rules = makeRulesAndAssert(withFrequencyOption: .monthly, interval: interval)
        XCTAssertEqual(rules.monthDayList?.count, 1)
    }
}
