@testable import MEGAFoundation
import XCTest

final class NSDate_DateTests: XCTestCase {
    func testIsToday_whenToday_expectedTrue() {
        let now = NSDate()
        XCTAssertTrue(now.isToday(), "isToday() should return true for the current date")
    }

    func testIsToday_whenDateIsNotToday_expectedFalse() throws {
        let notToday: Date? = NSCalendar.current.date(byAdding: .day, value: -1, to: Date())
        let _notToday = try XCTUnwrap(notToday, "notToday is nil")
        XCTAssertFalse((_notToday as NSDate).isToday(), "isToday() should return false for a date that is not today")
    }

    func testIsSameDayAs_whenDatesAreOnTheSameDay_expectedTrue() throws {
        let firstDay = NSDate(timeIntervalSince1970: .zero)
        let firstDayPlusHour = NSCalendar.current.date(byAdding: .hour, value: 1, to: firstDay as Date)
        let _firstDayPlusHour = try XCTUnwrap(firstDayPlusHour, "firstDayPlusHour is nil")
        XCTAssertTrue(firstDay.isSameDayAs(date: _firstDayPlusHour as NSDate), "isSameDayAs() should return true for two dates on the same day")
    }

    func testIsSameDayAs_whenDatesAreOnDifferentDays_expectedFalse() throws {
        let firstDay = NSDate(timeIntervalSince1970: .zero)
        let secondDay = NSCalendar.current.date(byAdding: .day, value: 1, to: firstDay as Date)
        let _secondDay = try XCTUnwrap(secondDay, "secondDay is nil")

        XCTAssertFalse(firstDay.isSameDayAs(date: _secondDay as NSDate), "isSameDayAs() should return false for two dates on different days")
    }
}
