import Foundation

extension DateFormatter {

    // MARK: - Formatter Custom Template Style

    /// Monday Jun 1, 2020
    @objc static func dateMediumWithWeekday(calendar: Calendar? = nil,
                                            timeZone: TimeZone? = nil,
                                            locale: Locale? = nil) -> DateFormatting {
        return fromTemplate("EEEEMMMddyyyy",
                            calendar: calendar,
                            timeZone: timeZone,
                            locale: locale)
    }
    
    /// Customise a date time formatter which follows provided unicode pattern. For unicode pattern please visit [here](https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table)
    /// - Parameters:
    ///   - template: The unicode Date Field Symbol Table
    ///   - calendar: `Calendar` instance for the formatter, `nil` for using formatter that use system defined `Calendar`.
    ///   - timeZone: `TimeZone` instance for the formatter, `nil` for using formatter that use system defined `TimeZone`.
    ///   - locale: `Locale` instance that for the formatter, `nil` for using formatter that use system defined `Locale`.
    /// - Returns: A instance conforms `DateFormatting` who can format a date into an human-readable string text.
    @objc static func fromTemplate(_ template: String,
                                   calendar: Calendar? = nil,
                                   timeZone: TimeZone? = nil,
                                   locale: Locale? = nil) -> DateFormatting {
        let style = DateStyle.dateStyleFactory.templateStyle(fromTemplate: template,
                                                             calendar: calendar,
                                                             timeZone: timeZone,
                                                             locale: locale)
        return DateFormatterPool.shared.dateFormatter(of: style)
    }
}
