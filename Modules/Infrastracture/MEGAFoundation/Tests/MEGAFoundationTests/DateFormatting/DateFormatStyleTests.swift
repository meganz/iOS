@testable import MEGAFoundation
import XCTest

class DateFormatStyleTests: XCTestCase {

    func testDateStyleFactoryCreatesSystemFormatter_WithSpecifiedCalendar_Locale_TimeZone() {
        // Given calendar timezone locale
        let calendar = Calendar(identifier: .gregorian)
        let timeZone = TimeZone(identifier: "America/New_York")!
        let locale = Locale(identifier: "en")
        let dateStyle: DateFormatter.Style = .full
        let timeStyle: DateFormatter.Style = .full
        
        // When get dateFormatter
        let dateFormatter = DateStyle.dateStyleFactory.systemStyle(
            ofDateStyle: dateStyle,
            timeStyle: timeStyle,
            relativeDateFormatting: true,
            calendar: calendar,
            timeZone: timeZone,
            locale: locale
        ).buildDateFormatter()
        
        // Then the formatter uses the right setting
        XCTAssertEqual(dateFormatter.calendar, calendar)
        XCTAssertEqual(dateFormatter.timeZone, timeZone)
        XCTAssertEqual(dateFormatter.locale, locale)
        XCTAssertEqual(dateFormatter.dateStyle, .full)
        XCTAssertEqual(dateFormatter.timeStyle, .full)
    }

    func testDateStyleFactoryCreatesCustomFormatter_WithSpecifiedCalendar_Locale_TimeZone() throws {
        // Given calendar timezone locale
        let calendar = Calendar(identifier: .gregorian)
        
        let timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let locale = Locale(identifier: "en")

        // When get dateFormatter
        let dateFormatter = DateStyle.dateStyleFactory.templateStyle(
            fromTemplate: "EEddyy",
            calendar: calendar,
            timeZone: timeZone,
            locale: locale).buildDateFormatter()

        // Then the formatter uses the right setting
        XCTAssertEqual(dateFormatter.calendar, calendar)
        XCTAssertEqual(dateFormatter.timeZone, timeZone)
        XCTAssertEqual(dateFormatter.locale, locale)
    }
}
