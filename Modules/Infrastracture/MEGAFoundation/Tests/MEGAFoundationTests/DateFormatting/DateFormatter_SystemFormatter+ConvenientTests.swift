@testable import MEGAFoundation
import XCTest

class DateFormatter_System_ConvenientTests: XCTestCase {

    func testShortTemplateDateFormatter_FormatDates_InDifferentLanguage() {
        let languageIdentifiers = [
            "en", "es", "en", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given 1 Jan 1970
        let date = Date(timeIntervalSince1970: 0)
        let locales = languageIdentifiers.map(Locale.init)

        let formattedDates = locales.map { (locale) -> String in
            let formatter = DateFormatter.dateShort(locale: locale)
            let result = formatter.localisedString(from: date)
            return result
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short

        let resultDates = locales.map { locale -> String in
            formatter.locale = locale
            return formatter.string(from: date)
        }

        // Then
        XCTAssertEqual(formattedDates, resultDates)
    }

    func testShortTemplateDateFormatter_FormatDates_InDifferentLanguage_CalendarGregorian() {
        let languageIdentifiers = [
            "en", "es", "en", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given 1 Jan 1970
        let date = Date(timeIntervalSince1970: 0)
        let locales = languageIdentifiers.map(Locale.init)
        let calendar = Calendar(identifier: .gregorian)

        let formattedDates = locales.map { (locale) -> String in
            let formatter = DateFormatter.dateShort(calendar: calendar, locale: locale)
            let result = formatter.localisedString(from: date)
            return result
        }
        
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .short

        let resultDates = locales.map { locale -> String in
            formatter.locale = locale
            return formatter.string(from: date)
        }

        // Then
        XCTAssertEqual(formattedDates, resultDates)
    }
}
