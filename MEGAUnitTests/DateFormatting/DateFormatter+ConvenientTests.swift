import XCTest
@testable import MEGA

class DateFormatter_ConvenientTests: XCTestCase {
    
    // MARK: - Short Formatter

    func testShortTemplateDateFormatter_FormatDates_InDifferentLanguage() {
        let languageIdentifiers = [
            "en", "es", "en", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given 1 Jan 1970
        let date = Date(timeIntervalSince1970: 0)
        let locales = languageIdentifiers.map(Locale.init)

        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> String in
            let formatter = DateFormatter.dateShortSystem(locale: locale)
            let result = formatter.localisedString(from: date)
            return result
        }

        // Then
        XCTAssertEqual(formattedDates, ["1/1/70", "1/1/70", "1/1/70", "01/01/70", "01-01-1970", "01.01.1970", "1970/1/1", "01/01/1970", "01/01/1970", "1970/01/01", "01.01.70", "1970. 1. 1.", "01.01.1970", "01/01/70", "01.01.1970", "01/01/1970", "1970/1/1", "١‏/١‏/١٩٧٠", "1/1/13"])
    }

    func testShortTemplateDateFormatter_FormatDates_InDifferentLanguage_CalendarGregorian() {
        let languageIdentifiers = [
            "en", "es", "en", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given 1 Jan 1970
        let date = Date(timeIntervalSince1970: 0)
        let locales = languageIdentifiers.map(Locale.init)
        let calendar = Calendar(identifier: .gregorian)

        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> String in
            let formatter = DateFormatter.dateShortSystem(calendar: calendar, locale: locale)
            let result = formatter.localisedString(from: date)
            return result
        }

        // Then
        XCTAssertEqual(formattedDates, ["1/1/70", "1/1/70", "1/1/70", "01/01/70", "01-01-1970", "01.01.1970", "1970/1/1", "01/01/1970", "01/01/1970", "1970/01/01", "01.01.70", "1970. 1. 1.", "01.01.1970", "01/01/70", "01.01.1970", "01/01/1970", "1970/1/1", "١‏/١‏/١٩٧٠", "1/1/70"])
    }

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

    // MARK: - Long Formatter

    func testLongTemplateDateFormatter_FormatDates_InDifferentLanguage() {
        let languageIdentifiers = [
            "en", "es", "en", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given 1 Jan 1970
        let date = Date(timeIntervalSince1970: 0)
        let locales = languageIdentifiers.map(Locale.init)

        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> String in
            let formatter = DateFormatter.dateLongSystem(locale: locale)
            let result = formatter.localisedString(from: date)
            return result
        }

        // Then
        XCTAssertEqual(formattedDates, ["January 1, 1970", "1 de enero de 1970", "January 1, 1970", "1 gennaio 1970", "1 januari 1970", "1 января 1970 г.", "1970年1月1日", "1 de janeiro de 1970", "1 janvier 1970", "1970年1月1日", "1. Januar 1970", "1970년 1월 1일", "1 stycznia 1970", "1 Januari 1970", "1 ianuarie 1970", "ngày 1 tháng 1, 1970", "1970年1月1日", "١ يناير، ١٩٧٠", "1 มกราคม 2513"])
    }

    func testLongTemplateDateFormatter_FormatDates_InDifferentLanguage_CalendarGregorian() {
        let languageIdentifiers = [
            "en", "es", "en", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given 1 Jan 1970
        let date = Date(timeIntervalSince1970: 0)
        let locales = languageIdentifiers.map(Locale.init)
        let calendar = Calendar(identifier: .gregorian)

        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> String in
            let formatter = DateFormatter.dateLongSystem(calendar: calendar, locale: locale)
            let result = formatter.localisedString(from: date)
            return result
        }

        // Then
        XCTAssertEqual(formattedDates, ["January 1, 1970", "1 de enero de 1970", "January 1, 1970", "1 gennaio 1970", "1 januari 1970", "1 января 1970 г.", "1970年1月1日", "1 de janeiro de 1970", "1 janvier 1970", "1970年1月1日", "1. Januar 1970", "1970년 1월 1일", "1 stycznia 1970", "1 Januari 1970", "1 ianuarie 1970", "ngày 1 tháng 1, 1970", "1970年1月1日", "١ يناير، ١٩٧٠", "1 มกราคม ค.ศ. 1970"])
    }

    // MARK: - Full Formatter

    func testFullTemplateDateFormatter_FormatDates_InDifferentLanguage() {
        let languageIdentifiers = [
            "en", "es", "en", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given 1 Jan 1970
        let date = Date(timeIntervalSince1970: 0)
        let locales = languageIdentifiers.map(Locale.init)

        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> String in
            let formatter = DateFormatter.dateFullSystem(locale: locale)
            let result = formatter.localisedString(from: date)
            return result
        }

        // Then
        XCTAssertEqual(formattedDates, ["Thursday, January 1, 1970", "jueves, 1 de enero de 1970", "Thursday, January 1, 1970", "giovedì 1 gennaio 1970", "donderdag 1 januari 1970", "четверг, 1 января 1970 г.", "1970年1月1日 星期四", "quinta-feira, 1 de janeiro de 1970", "jeudi 1 janvier 1970", "1970年1月1日 木曜日", "Donnerstag, 1. Januar 1970", "1970년 1월 1일 목요일", "czwartek, 1 stycznia 1970", "Kamis, 01 Januari 1970", "joi, 1 ianuarie 1970", "Thứ Năm, ngày 1 tháng 1, 1970", "1970年1月1日 星期四", "الخميس، ١ يناير، ١٩٧٠", "วันพฤหัสบดีที่ 1 มกราคม พ.ศ. 2513"])
    }

    func testFullTemplateDateFormatter_FormatDates_InDifferentLanguage_CalendarGregorian() {
        let languageIdentifiers = [
            "en", "es", "en", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given 1 Jan 1970
        let date = Date(timeIntervalSince1970: 0)
        let locales = languageIdentifiers.map(Locale.init)
        let calendar = Calendar(identifier: .gregorian)

        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> String in
            let formatter = DateFormatter.dateFullSystem(calendar: calendar, locale: locale)
            let result = formatter.localisedString(from: date)
            return result
        }

        // Then
        XCTAssertEqual(formattedDates, ["Thursday, January 1, 1970", "jueves, 1 de enero de 1970", "Thursday, January 1, 1970", "giovedì 1 gennaio 1970", "donderdag 1 januari 1970", "четверг, 1 января 1970 г.", "1970年1月1日 星期四", "quinta-feira, 1 de janeiro de 1970", "jeudi 1 janvier 1970", "1970年1月1日 木曜日", "Donnerstag, 1. Januar 1970", "1970년 1월 1일 목요일", "czwartek, 1 stycznia 1970", "Kamis, 01 Januari 1970", "joi, 1 ianuarie 1970", "Thứ Năm, ngày 1 tháng 1, 1970", "1970年1月1日 星期四", "الخميس، ١ يناير، ١٩٧٠", "วันพฤหัสบดีที่ 1 มกราคม ค.ศ. 1970"])
    }
}
