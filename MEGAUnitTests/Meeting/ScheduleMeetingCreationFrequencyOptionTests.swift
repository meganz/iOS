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
    
    func testCreateRules_withIntervalAsOneForWeekly_shouldMatch() throws {
       try assertWeekly(withInterval: 1)
    }
    
    func testCreateRules_withIntervalMoreThanOneForWeekly_shouldMatch() throws {
        try assertWeekly(withInterval: 3)
    }
    
    func testCreateRules_withIntervalAsOneForMonthly_shouldMatch() throws {
        try assertMonthly(withInterval: 1)
    }
    
    func testCreateRules_withIntervalMoreThanOneForMonthly_shouldMatch() throws {
        try assertMonthly(withInterval: 3)
    }
    
    // MARK: - Private methods.
    private func assertDaily(withInterval interval: Int, startDate: Date = Date()) {
        let rules = makeRulesAndAssert(withFrequencyOption: .daily, interval: interval, startDate: startDate)
        XCTAssertEqual(rules.weekDayList, Array(1...7))
    }
    
    private func assertWeekly(withInterval interval: Int) throws {
        let sampleDate = try XCTUnwrap(sampleDate())
        let rules = makeRulesAndAssert(withFrequencyOption: .weekly, interval: interval, startDate: sampleDate)
        XCTAssertEqual(rules.weekDayList, [3])
    }
    
    private func makeRulesAndAssert(
        withFrequencyOption frequencyOption: ScheduleMeetingCreationFrequencyOption,
        interval: Int,
        startDate: Date
    ) -> ScheduledMeetingRulesEntity {
        let rules = frequencyOption.createRules(usingInterval: interval, startDate: startDate)
        XCTAssertEqual(rules.frequency, frequencyOption.frequency)
        XCTAssertEqual(rules.interval, interval)
        return rules
    }
    
    private func assertMonthly(withInterval interval: Int) throws {
        let sampleDate = try XCTUnwrap(sampleDate())
        let rules = makeRulesAndAssert(withFrequencyOption: .monthly, interval: interval, startDate: sampleDate)
        XCTAssertEqual(rules.monthDayList, [14])
    }
    
    private func sampleDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.date(from: "14/06/2023")
    }
}
