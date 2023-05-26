import XCTest
@testable import MEGAFoundation

class DateFormatter_SystemRelative_ConvenientTests: XCTestCase {

    private let oneDayTimeInterval: TimeInterval = 60 * 60 * 24 * 1
    private lazy var todayTimeInverval: TimeInterval = 0
    private lazy var tomorrowTimeInverval: TimeInterval = oneDayTimeInterval * 1
    private lazy var dayAfterTomorrowTimeInverval: TimeInterval = oneDayTimeInterval * 2
    private lazy var yesterdayTimeInverval: TimeInterval = oneDayTimeInterval * -1
    private lazy var dayBeforeYesterdayTimeInverval: TimeInterval = oneDayTimeInterval * -2

    private lazy var today = Date(timeIntervalSinceNow: 0)
    private lazy var tomorrow = Date(timeIntervalSinceNow: tomorrowTimeInverval)
    private lazy var dayAfterTomorrow = Date(timeIntervalSinceNow: dayAfterTomorrowTimeInverval)
    private lazy var yesterday = Date(timeIntervalSinceNow: yesterdayTimeInverval)
    private lazy var dayBeforeYesterday = Date(timeIntervalSinceNow: dayBeforeYesterdayTimeInverval)

    // MARK: - Short Formatter

    func testShortTemplateDateFormatter_FormatDates_InDifferentLanguage() {
        let languageIdentifiers = [
            "en", "es", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given 1 Jan 1970
        let locales = languageIdentifiers.map(Locale.init)

        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> (String, String, String, String, String) in
            let formatter = DateFormatter.dateRelativeShort(locale: locale)
            let todayFormatted = formatter.localisedString(from: today)
            let tomorrowFormatted = formatter.localisedString(from: tomorrow)
            let dayAfterTomorrowFormatted = formatter.localisedString(from: dayAfterTomorrow)
            let yesterdayFormatted = formatter.localisedString(from: yesterday)
            let dayBeforeyesterdayFormatted = formatter.localisedString(from: dayBeforeYesterday)
            return (todayFormatted, tomorrowFormatted, yesterdayFormatted, dayAfterTomorrowFormatted, dayBeforeyesterdayFormatted)
        }

        // Then
        XCTAssertEqual(formattedDates.map { $0.0 }, ["Today", "hoy", "oggi", "Vandaag", "Сегодня", "今天", "Hoje", "aujourd’hui", "今日", "Heute", "오늘", "Dzisiaj", "Hari ini", "azi", "Hôm nay", "今天", "اليوم", "วันนี้"])
        XCTAssertEqual(formattedDates.map { $0.1 }, ["Tomorrow", "mañana", "domani", "Morgen", "Завтра", "明天", "Amanhã", "demain", "明日", "Morgen", "내일", "Jutro", "Besok", "mâine", "Ngày mai", "明天", "غدًا", "พรุ่งนี้"])
        XCTAssertEqual(formattedDates.map { $0.2 }, ["Yesterday", "ayer", "ieri", "Gisteren", "Вчера", "昨天", "Ontem", "hier", "昨日", "Gestern", "어제", "Wczoraj", "Kemarin", "ieri", "Hôm qua", "昨天", "أمس", "เมื่อวาน"])
        XCTAssertEqual(formattedDates.map { $0.3 }[1...], ["pasado mañana", "dopodomani", "Overmorgen", "Послезавтра", "後天", "Depois de amanhã", "après-demain", "明後日", "Übermorgen", "모레", "Pojutrze", "Lusa", "poimâine", "Ngày kia", "后天", "بعد الغد", "มะรืนนี้"])
        XCTAssertEqual(formattedDates.map { $0.4 }[1...], ["anteayer", "l'altro ieri", "Eergisteren", "Позавчера", "前天", "Anteontem", "avant-hier", "一昨日", "Vorgestern", "그저께", "Przedwczoraj", "Kemarin lusa", "alaltăieri", "Hôm kia", "前天", "أول أمس", "เมื่อวานซืน"])
    }

    func testShortTemplateDateFormatter_FormatDates_InDifferentLanguage_CalendarGregorian() {
        let languageIdentifiers = [
            "en", "es", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given locales and gregorian calendar
        let locales = languageIdentifiers.map(Locale.init)
        let calendar = Calendar(identifier: .gregorian)

        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> (String, String, String, String, String) in
            let formatter = DateFormatter.dateRelativeShort(calendar: calendar, locale: locale)
            let todayFormatted = formatter.localisedString(from: today)
            let tomorrowFormatted = formatter.localisedString(from: tomorrow)
            let dayAfterTomorrowFormatted = formatter.localisedString(from: dayAfterTomorrow)
            let yesterdayFormatted = formatter.localisedString(from: yesterday)
            let dayBeforeyesterdayFormatted = formatter.localisedString(from: dayBeforeYesterday)
            return (todayFormatted, tomorrowFormatted, yesterdayFormatted, dayAfterTomorrowFormatted, dayBeforeyesterdayFormatted)
        }

        // Then
        XCTAssertEqual(formattedDates.map { $0.0 }, ["Today", "hoy", "oggi", "Vandaag", "Сегодня", "今天", "Hoje", "aujourd’hui", "今日", "Heute", "오늘", "Dzisiaj", "Hari ini", "azi", "Hôm nay", "今天", "اليوم", "วันนี้"])
        XCTAssertEqual(formattedDates.map { $0.1 }, ["Tomorrow", "mañana", "domani", "Morgen", "Завтра", "明天", "Amanhã", "demain", "明日", "Morgen", "내일", "Jutro", "Besok", "mâine", "Ngày mai", "明天", "غدًا", "พรุ่งนี้"])
        XCTAssertEqual(formattedDates.map { $0.2 }, ["Yesterday", "ayer", "ieri", "Gisteren", "Вчера", "昨天", "Ontem", "hier", "昨日", "Gestern", "어제", "Wczoraj", "Kemarin", "ieri", "Hôm qua", "昨天", "أمس", "เมื่อวาน"])
        XCTAssertEqual(formattedDates.map { $0.3 }[1...], ["pasado mañana", "dopodomani", "Overmorgen", "Послезавтра", "後天", "Depois de amanhã", "après-demain", "明後日", "Übermorgen", "모레", "Pojutrze", "Lusa", "poimâine", "Ngày kia", "后天", "بعد الغد", "มะรืนนี้"])
        XCTAssertEqual(formattedDates.map { $0.4 }[1...], ["anteayer", "l'altro ieri", "Eergisteren", "Позавчера", "前天", "Anteontem", "avant-hier", "一昨日", "Vorgestern", "그저께", "Przedwczoraj", "Kemarin lusa", "alaltăieri", "Hôm kia", "前天", "أول أمس", "เมื่อวานซืน"])
    }

    // MARK: - Medium Formatter

    func testMediumTemplateDateFormatter_FormatDates_InDifferentLanguage() {
        let languageIdentifiers = [
            "en", "es", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given 1 Jan 1970
        let locales = languageIdentifiers.map(Locale.init)

        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> (String, String, String, String, String) in
            let formatter = DateFormatter.dateRelativeMedium(locale: locale)
            let todayFormatted = formatter.localisedString(from: today)
            let tomorrowFormatted = formatter.localisedString(from: tomorrow)
            let dayAfterTomorrowFormatted = formatter.localisedString(from: dayAfterTomorrow)
            let yesterdayFormatted = formatter.localisedString(from: yesterday)
            let dayBeforeyesterdayFormatted = formatter.localisedString(from: dayBeforeYesterday)
            return (todayFormatted, tomorrowFormatted, yesterdayFormatted, dayAfterTomorrowFormatted, dayBeforeyesterdayFormatted)
        }

        // Then
        XCTAssertEqual(formattedDates.map { $0.0 }, ["Today", "hoy", "oggi", "Vandaag", "Сегодня", "今天", "Hoje", "aujourd’hui", "今日", "Heute", "오늘", "Dzisiaj", "Hari ini", "azi", "Hôm nay", "今天", "اليوم", "วันนี้"])
        XCTAssertEqual(formattedDates.map { $0.1 }, ["Tomorrow", "mañana", "domani", "Morgen", "Завтра", "明天", "Amanhã", "demain", "明日", "Morgen", "내일", "Jutro", "Besok", "mâine", "Ngày mai", "明天", "غدًا", "พรุ่งนี้"])
        XCTAssertEqual(formattedDates.map { $0.2 }, ["Yesterday", "ayer", "ieri", "Gisteren", "Вчера", "昨天", "Ontem", "hier", "昨日", "Gestern", "어제", "Wczoraj", "Kemarin", "ieri", "Hôm qua", "昨天", "أمس", "เมื่อวาน"])
        XCTAssertEqual(formattedDates.map { $0.3 }[1...], ["pasado mañana", "dopodomani", "Overmorgen", "Послезавтра", "後天", "Depois de amanhã", "après-demain", "明後日", "Übermorgen", "모레", "Pojutrze", "Lusa", "poimâine", "Ngày kia", "后天", "بعد الغد", "มะรืนนี้"])
        XCTAssertEqual(formattedDates.map { $0.4 }[1...], ["anteayer", "l'altro ieri", "Eergisteren", "Позавчера", "前天", "Anteontem", "avant-hier", "一昨日", "Vorgestern", "그저께", "Przedwczoraj", "Kemarin lusa", "alaltăieri", "Hôm kia", "前天", "أول أمس", "เมื่อวานซืน"])
    }

    func testMediumTemplateDateFormatter_FormatDates_InDifferentLanguage_CalendarGregorian() {
        let languageIdentifiers = [
            "en", "es", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given locales and gregorian calendar
        let locales = languageIdentifiers.map(Locale.init)
        let calendar = Calendar(identifier: .gregorian)

        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> (String, String, String, String, String) in
            let formatter = DateFormatter.dateRelativeMedium(calendar: calendar, locale: locale)
            let todayFormatted = formatter.localisedString(from: today)
            let tomorrowFormatted = formatter.localisedString(from: tomorrow)
            let dayAfterTomorrowFormatted = formatter.localisedString(from: dayAfterTomorrow)
            let yesterdayFormatted = formatter.localisedString(from: yesterday)
            let dayBeforeyesterdayFormatted = formatter.localisedString(from: dayBeforeYesterday)
            return (todayFormatted, tomorrowFormatted, yesterdayFormatted, dayAfterTomorrowFormatted, dayBeforeyesterdayFormatted)
        }

        // Then
        XCTAssertEqual(formattedDates.map { $0.0 }, ["Today", "hoy", "oggi", "Vandaag", "Сегодня", "今天", "Hoje", "aujourd’hui", "今日", "Heute", "오늘", "Dzisiaj", "Hari ini", "azi", "Hôm nay", "今天", "اليوم", "วันนี้"])
        XCTAssertEqual(formattedDates.map { $0.1 }, ["Tomorrow", "mañana", "domani", "Morgen", "Завтра", "明天", "Amanhã", "demain", "明日", "Morgen", "내일", "Jutro", "Besok", "mâine", "Ngày mai", "明天", "غدًا", "พรุ่งนี้"])
        XCTAssertEqual(formattedDates.map { $0.2 }, ["Yesterday", "ayer", "ieri", "Gisteren", "Вчера", "昨天", "Ontem", "hier", "昨日", "Gestern", "어제", "Wczoraj", "Kemarin", "ieri", "Hôm qua", "昨天", "أمس", "เมื่อวาน"])
        XCTAssertEqual(formattedDates.map { $0.3 }[1...], ["pasado mañana", "dopodomani", "Overmorgen", "Послезавтра", "後天", "Depois de amanhã", "après-demain", "明後日", "Übermorgen", "모레", "Pojutrze", "Lusa", "poimâine", "Ngày kia", "后天", "بعد الغد", "มะรืนนี้"])
        XCTAssertEqual(formattedDates.map { $0.4 }[1...], ["anteayer", "l'altro ieri", "Eergisteren", "Позавчера", "前天", "Anteontem", "avant-hier", "一昨日", "Vorgestern", "그저께", "Przedwczoraj", "Kemarin lusa", "alaltăieri", "Hôm kia", "前天", "أول أمس", "เมื่อวานซืน"])
    }

    // MARK: - Long Formatter

    func testLongTemplateDateFormatter_FormatDates_InDifferentLanguage() {
        let languageIdentifiers = [
            "en", "es", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given 1 Jan 1970
        let locales = languageIdentifiers.map(Locale.init)

        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> (String, String, String, String, String) in
            let formatter = DateFormatter.dateRelativeLong(locale: locale)
            let todayFormatted = formatter.localisedString(from: today)
            let tomorrowFormatted = formatter.localisedString(from: tomorrow)
            let dayAfterTomorrowFormatted = formatter.localisedString(from: dayAfterTomorrow)
            let yesterdayFormatted = formatter.localisedString(from: yesterday)
            let dayBeforeyesterdayFormatted = formatter.localisedString(from: dayBeforeYesterday)
            return (todayFormatted, tomorrowFormatted, yesterdayFormatted, dayAfterTomorrowFormatted, dayBeforeyesterdayFormatted)
        }

        // Then
        XCTAssertEqual(formattedDates.map { $0.0 }, ["Today", "hoy", "oggi", "Vandaag", "Сегодня", "今天", "Hoje", "aujourd’hui", "今日", "Heute", "오늘", "Dzisiaj", "Hari ini", "azi", "Hôm nay", "今天", "اليوم", "วันนี้"])
        XCTAssertEqual(formattedDates.map { $0.1 }, ["Tomorrow", "mañana", "domani", "Morgen", "Завтра", "明天", "Amanhã", "demain", "明日", "Morgen", "내일", "Jutro", "Besok", "mâine", "Ngày mai", "明天", "غدًا", "พรุ่งนี้"])
        XCTAssertEqual(formattedDates.map { $0.2 }, ["Yesterday", "ayer", "ieri", "Gisteren", "Вчера", "昨天", "Ontem", "hier", "昨日", "Gestern", "어제", "Wczoraj", "Kemarin", "ieri", "Hôm qua", "昨天", "أمس", "เมื่อวาน"])
        XCTAssertEqual(formattedDates.map { $0.3 }[1...], ["pasado mañana", "dopodomani", "Overmorgen", "Послезавтра", "後天", "Depois de amanhã", "après-demain", "明後日", "Übermorgen", "모레", "Pojutrze", "Lusa", "poimâine", "Ngày kia", "后天", "بعد الغد", "มะรืนนี้"])
        XCTAssertEqual(formattedDates.map { $0.4 }[1...], ["anteayer", "l'altro ieri", "Eergisteren", "Позавчера", "前天", "Anteontem", "avant-hier", "一昨日", "Vorgestern", "그저께", "Przedwczoraj", "Kemarin lusa", "alaltăieri", "Hôm kia", "前天", "أول أمس", "เมื่อวานซืน"])
    }

    func testLongTemplateDateFormatter_FormatDates_InDifferentLanguage_CalendarGregorian() {
        let languageIdentifiers = [
            "en", "es", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given locales and gregorian calendar
        let locales = languageIdentifiers.map(Locale.init)
        let calendar = Calendar(identifier: .gregorian)

        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> (String, String, String, String, String) in
            let formatter = DateFormatter.dateRelativeLong(calendar: calendar, locale: locale)
            let todayFormatted = formatter.localisedString(from: today)
            let tomorrowFormatted = formatter.localisedString(from: tomorrow)
            let dayAfterTomorrowFormatted = formatter.localisedString(from: dayAfterTomorrow)
            let yesterdayFormatted = formatter.localisedString(from: yesterday)
            let dayBeforeyesterdayFormatted = formatter.localisedString(from: dayBeforeYesterday)
            return (todayFormatted, tomorrowFormatted, yesterdayFormatted, dayAfterTomorrowFormatted, dayBeforeyesterdayFormatted)
        }

        // Then
        XCTAssertEqual(formattedDates.map { $0.0 }, ["Today", "hoy", "oggi", "Vandaag", "Сегодня", "今天", "Hoje", "aujourd’hui", "今日", "Heute", "오늘", "Dzisiaj", "Hari ini", "azi", "Hôm nay", "今天", "اليوم", "วันนี้"])
        XCTAssertEqual(formattedDates.map { $0.1 }, ["Tomorrow", "mañana", "domani", "Morgen", "Завтра", "明天", "Amanhã", "demain", "明日", "Morgen", "내일", "Jutro", "Besok", "mâine", "Ngày mai", "明天", "غدًا", "พรุ่งนี้"])
        XCTAssertEqual(formattedDates.map { $0.2 }, ["Yesterday", "ayer", "ieri", "Gisteren", "Вчера", "昨天", "Ontem", "hier", "昨日", "Gestern", "어제", "Wczoraj", "Kemarin", "ieri", "Hôm qua", "昨天", "أمس", "เมื่อวาน"])
        XCTAssertEqual(formattedDates.map { $0.3 }[1...], ["pasado mañana", "dopodomani", "Overmorgen", "Послезавтра", "後天", "Depois de amanhã", "après-demain", "明後日", "Übermorgen", "모레", "Pojutrze", "Lusa", "poimâine", "Ngày kia", "后天", "بعد الغد", "มะรืนนี้"])
        XCTAssertEqual(formattedDates.map { $0.4 }[1...], ["anteayer", "l'altro ieri", "Eergisteren", "Позавчера", "前天", "Anteontem", "avant-hier", "一昨日", "Vorgestern", "그저께", "Przedwczoraj", "Kemarin lusa", "alaltăieri", "Hôm kia", "前天", "أول أمس", "เมื่อวานซืน"])
    }

    // MARK: - Full Formatter

    func testFullTemplateDateFormatter_FormatDates_InDifferentLanguage() {
        let languageIdentifiers = [
            "en", "es", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
        ]

        // Given 1 Jan 1970
        let locales = languageIdentifiers.map(Locale.init)

        // When format with `medium` formatter
        let formattedDates = locales.map { (locale) -> (String, String, String, String, String) in
            let formatter = DateFormatter.dateRelativeFull(locale: locale)
            let todayFormatted = formatter.localisedString(from: today)
            let tomorrowFormatted = formatter.localisedString(from: tomorrow)
            let dayAfterTomorrowFormatted = formatter.localisedString(from: dayAfterTomorrow)
            let yesterdayFormatted = formatter.localisedString(from: yesterday)
            let dayBeforeyesterdayFormatted = formatter.localisedString(from: dayBeforeYesterday)
            return (todayFormatted, tomorrowFormatted, yesterdayFormatted, dayAfterTomorrowFormatted, dayBeforeyesterdayFormatted)
        }

        // Then
        XCTAssertEqual(formattedDates.map { $0.0 }, ["Today", "hoy", "oggi", "Vandaag", "Сегодня", "今天", "Hoje", "aujourd’hui", "今日", "Heute", "오늘", "Dzisiaj", "Hari ini", "azi", "Hôm nay", "今天", "اليوم", "วันนี้"])
        XCTAssertEqual(formattedDates.map { $0.1 }, ["Tomorrow", "mañana", "domani", "Morgen", "Завтра", "明天", "Amanhã", "demain", "明日", "Morgen", "내일", "Jutro", "Besok", "mâine", "Ngày mai", "明天", "غدًا", "พรุ่งนี้"])
        XCTAssertEqual(formattedDates.map { $0.2 }, ["Yesterday", "ayer", "ieri", "Gisteren", "Вчера", "昨天", "Ontem", "hier", "昨日", "Gestern", "어제", "Wczoraj", "Kemarin", "ieri", "Hôm qua", "昨天", "أمس", "เมื่อวาน"])
        XCTAssertEqual(formattedDates.map { $0.3 }[1...], ["pasado mañana", "dopodomani", "Overmorgen", "Послезавтра", "後天", "Depois de amanhã", "après-demain", "明後日", "Übermorgen", "모레", "Pojutrze", "Lusa", "poimâine", "Ngày kia", "后天", "بعد الغد", "มะรืนนี้"])
        XCTAssertEqual(formattedDates.map { $0.4 }[1...], ["anteayer", "l'altro ieri", "Eergisteren", "Позавчера", "前天", "Anteontem", "avant-hier", "一昨日", "Vorgestern", "그저께", "Przedwczoraj", "Kemarin lusa", "alaltăieri", "Hôm kia", "前天", "أول أمس", "เมื่อวานซืน"])
    }

    func testFullTemplateDateFormatter_FormatDates_InDifferentLanguage_CalendarGregorian() {
       let languageIdentifiers = [
           "en", "es", "it", "nl", "ru", "zh-TW", "pt-BR", "fr", "ja", "de", "ko", "pl", "id", "ro", "vi", "zh-CN", "ar", "th"
       ]

       // Given locales and gregorian calendar
       let locales = languageIdentifiers.map(Locale.init)
       let calendar = Calendar(identifier: .gregorian)

       // When format with `full` formatter
       let formattedDates = locales.map { (locale) -> (String, String, String, String, String) in
           let formatter = DateFormatter.dateRelativeFull(calendar: calendar, locale: locale)
           let todayFormatted = formatter.localisedString(from: today)
           let tomorrowFormatted = formatter.localisedString(from: tomorrow)
           let dayAfterTomorrowFormatted = formatter.localisedString(from: dayAfterTomorrow)
           let yesterdayFormatted = formatter.localisedString(from: yesterday)
           let dayBeforeyesterdayFormatted = formatter.localisedString(from: dayBeforeYesterday)
           return (todayFormatted, tomorrowFormatted, yesterdayFormatted, dayAfterTomorrowFormatted, dayBeforeyesterdayFormatted)
       }

       // Then
       XCTAssertEqual(formattedDates.map { $0.0 }, ["Today", "hoy", "oggi", "Vandaag", "Сегодня", "今天", "Hoje", "aujourd’hui", "今日", "Heute", "오늘", "Dzisiaj", "Hari ini", "azi", "Hôm nay", "今天", "اليوم", "วันนี้"])
       XCTAssertEqual(formattedDates.map { $0.1 }, ["Tomorrow", "mañana", "domani", "Morgen", "Завтра", "明天", "Amanhã", "demain", "明日", "Morgen", "내일", "Jutro", "Besok", "mâine", "Ngày mai", "明天", "غدًا", "พรุ่งนี้"])
       XCTAssertEqual(formattedDates.map { $0.2 }, ["Yesterday", "ayer", "ieri", "Gisteren", "Вчера", "昨天", "Ontem", "hier", "昨日", "Gestern", "어제", "Wczoraj", "Kemarin", "ieri", "Hôm qua", "昨天", "أمس", "เมื่อวาน"])
       XCTAssertEqual(formattedDates.map { $0.3 }[1...], ["pasado mañana", "dopodomani", "Overmorgen", "Послезавтра", "後天", "Depois de amanhã", "après-demain", "明後日", "Übermorgen", "모레", "Pojutrze", "Lusa", "poimâine", "Ngày kia", "后天", "بعد الغد", "มะรืนนี้"])
       XCTAssertEqual(formattedDates.map { $0.4 }[1...], ["anteayer", "l'altro ieri", "Eergisteren", "Позавчера", "前天", "Anteontem", "avant-hier", "一昨日", "Vorgestern", "그저께", "Przedwczoraj", "Kemarin lusa", "alaltăieri", "Hôm kia", "前天", "أول أمس", "เมื่อวานซืน"])
    }
}
