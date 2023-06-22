@testable import MEGAFoundation
import XCTest

class DateTemplateStyleTests: XCTestCase {

    func testDateStyleFactoryCreatesTemplateFormatter_WithSpecifiedCalendar_Locale_TimeZone() {
        // Given calendar timezone locale
        let calendar = Calendar(identifier: .gregorian)
        let timeZone = TimeZone(identifier: "America/New_York")!
        let locale = Locale(identifier: "en")
        // When get dateFormatter
        let dateFormatter = DateStyle.dateStyleFactory.templateStyle(fromTemplate: "MMddyy",
                                                                     calendar: calendar,
                                                                     timeZone: timeZone,
                                                                     locale: locale).buildDateFormatter()
        
        // Then the formatter uses the right setting
        XCTAssertEqual(dateFormatter.calendar, calendar)
        XCTAssertEqual(dateFormatter.timeZone, timeZone)
        XCTAssertEqual(dateFormatter.locale, locale)
    }
}
