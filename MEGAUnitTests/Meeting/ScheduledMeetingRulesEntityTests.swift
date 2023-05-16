import XCTest
@testable import MEGA
import MEGADomain

final class ScheduledMeetingRulesEntityTests: XCTestCase {
    
    func testReset_neverOption_shouldMatch() throws {
        let date = try XCTUnwrap(sampleDate())
        var rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [1])
        rules.reset(toFrequency: .invalid, usingStartDate: date)
        XCTAssert(rules.frequency == .invalid)
        XCTAssert(rules.monthDayList == nil)
        XCTAssert(rules.weekDayList == nil)
        XCTAssert(rules.monthWeekDayList == nil)
    }
    
    func testReset_dailyOption_shouldMatch() throws {
        let date = try XCTUnwrap(sampleDate())
        var rules = ScheduledMeetingRulesEntity(frequency: .invalid)
        rules.reset(toFrequency: .daily, usingStartDate: date)
        XCTAssert(rules.frequency == .daily)
        XCTAssert(rules.weekDayList == Array(1...7))
        XCTAssert(rules.monthDayList == nil)
        XCTAssert(rules.monthWeekDayList == nil)
    }
    
    func testReset_weeklyOption_shouldMatch() throws {
        let date = try XCTUnwrap(sampleDate())
        var rules = ScheduledMeetingRulesEntity(frequency: .invalid)
        rules.reset(toFrequency: .weekly, usingStartDate: date)
        XCTAssert(rules.frequency == .weekly)
        XCTAssert(rules.weekDayList == [2])
        XCTAssert(rules.monthDayList == nil)
        XCTAssert(rules.monthWeekDayList == nil)
    }
    
    func testReset_monthlyOption_shouldMatch() throws {
        let date = try XCTUnwrap(sampleDate())
        var rules = ScheduledMeetingRulesEntity(frequency: .invalid)
        rules.reset(toFrequency: .monthly, usingStartDate: date)
        XCTAssert(rules.frequency == .monthly)
        XCTAssert(rules.monthDayList == [16])
        XCTAssert(rules.weekDayList == nil)
        XCTAssert(rules.monthWeekDayList == nil)
    }
    
    func testUpdateDayList_neverOption_shouldMatch() throws {
        let date = try XCTUnwrap(sampleDate())
        var rules = ScheduledMeetingRulesEntity(frequency: .invalid)
        rules.updateDayList(usingStartDate: date)
        XCTAssert(rules.frequency == .invalid)
        XCTAssert(rules.monthDayList == nil)
        XCTAssert(rules.weekDayList == nil)
        XCTAssert(rules.monthWeekDayList == nil)
    }
    
    func testUpdateDayList_dailyOption_shouldMatch() throws {
        let date = try XCTUnwrap(sampleDate())
        var rules = ScheduledMeetingRulesEntity(frequency: .daily)
        rules.updateDayList(usingStartDate: date)
        XCTAssert(rules.frequency == .daily)
        XCTAssert(rules.monthDayList == nil)
        XCTAssert(rules.weekDayList == Array(1...7))
        XCTAssert(rules.monthWeekDayList == nil)
    }
    
    func testUpdateDayList_weeklyOption_shouldMatch() throws {
        let date = try XCTUnwrap(sampleDate())
        var rules = ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: [1])
        rules.updateDayList(usingStartDate: date)
        XCTAssert(rules.frequency == .weekly)
        XCTAssert(rules.monthDayList == nil)
        XCTAssert(rules.weekDayList == [2])
        XCTAssert(rules.monthWeekDayList == nil)
    }
    
    func testUpdateDayList_monthlyOption_shouldMatch() throws {
        let date = try XCTUnwrap(sampleDate())
        var rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [1])
        rules.updateDayList(usingStartDate: date)
        XCTAssert(rules.frequency == .monthly)
        XCTAssert(rules.monthDayList == [16])
        XCTAssert(rules.weekDayList == nil)
        XCTAssert(rules.monthWeekDayList == nil)
    }
    
    //MARK: - Private methods.
    
    private func sampleDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.date(from: "16/05/2023")
    }
    
}
