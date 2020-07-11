import XCTest
@testable import MEGA

class DateFormatter_ConvenientTests: XCTestCase {
    
    // MARK: - Medium Formatter

    func testMediumTemplateDateFormatter_FormatDates_InDifferentLanguage() {
        let languageIdentifiers = [
            "en", "es", "en", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]
        
        // Given 1 Jan 1970
        let date = Date(timeIntervalSince1970: 0)
        let locales = languageIdentifiers.map(Locale.init)
        
        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> String in
            let formatter = DateFormatter.dateMediumSystem(locale: locale)
            let result = formatter.localisedString(from: date)
            return result
        }
        
        // Then
        XCTAssertEqual(formattedDates, ["Jan 1, 1970", "1 ene 1970", "Jan 1, 1970", "1 gen 1970", "1 jan. 1970", "1 янв. 1970 г.", "1970年1月1日", "1 de jan de 1970", "1 janv. 1970", "1970/01/01", "01.01.1970", "1970. 1. 1.", "01.01.1970", "1 Jan 1970", "1 ian. 1970", "ngày 1 thg 1, 1970", "1970年1月1日", "٠١‏/٠١‏/١٩٧٠", "1 ม.ค. 2513"])
    }
    
    func testMediumTemplateDateFormatter_FormatDates_InDifferentLanguage_CalendarGregorian() {
        let languageIdentifiers = [
            "en", "es", "en", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]
        
        // Given 1 Jan 1970
        let date = Date(timeIntervalSince1970: 0)
        let locales = languageIdentifiers.map(Locale.init)
        let calendar = Calendar(identifier: .gregorian)
        
        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> String in
            let formatter = DateFormatter.dateMediumSystem(calendar: calendar, locale: locale)
            let result = formatter.localisedString(from: date)
            return result
        }
        
        // Then
        XCTAssertEqual(formattedDates, ["Jan 1, 1970", "1 ene 1970", "Jan 1, 1970", "1 gen 1970", "1 jan. 1970", "1 янв. 1970 г.", "1970年1月1日", "1 de jan de 1970", "1 janv. 1970", "1970/01/01", "01.01.1970", "1970. 1. 1.", "01.01.1970", "1 Jan 1970", "1 ian. 1970", "ngày 1 thg 1, 1970", "1970年1月1日", "٠١‏/٠١‏/١٩٧٠", "1 ม.ค. 1970"])
    }
}
