import Foundation
@testable import MEGAFoundation
import XCTest

final class DateFormatter_TemplateFormatterTests: XCTestCase {

    private let date = Date(timeIntervalSince1970: 0)

    func test_dateMediumWithWeekday_returnsCorrectFormat() {
        let formatter = DateFormatter.dateMediumWithWeekday(
            timeZone: TimeZone.GMT,
            locale: Locale(identifier: "en_US")
        )
        let dateString = formatter.localisedString(from: date)
        XCTAssertEqual(dateString, "Thursday, Jan 01, 1970", "dateMediumWithWeekday should format the date correctly")
    }

    func test_yearTemplate_defaultValue_returnsCorrectFormat() {
        let formatter = DateFormatter.yearTemplate(
            timeZone: TimeZone.GMT,
            locale: Locale(identifier: "en_US")
        )
        let dateString = formatter.localisedString(from: date)
        XCTAssertEqual(dateString, "1970", "yearTemplate should format the date correctly")
    }

    func test_monthTemplate_defaultValue_returnsCorrectFormat() {
        let formatter = DateFormatter.monthTemplate(
            timeZone: TimeZone.GMT,
            locale: Locale(identifier: "en_US")
        )
        let dateString = formatter.localisedString(from: date)
        XCTAssertEqual(dateString, "Jan 1970", "monthTemplate should format the date correctly")
    }
}
