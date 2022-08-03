import Foundation

public extension DateFormatter {

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
    
    /// Return a date formatting object using year component template
    /// - Parameters:
    ///   - calendar: The calendar for the date format
    ///   - timeZone: The time zone for the date fomat
    ///   - locale: The locale for the date format
    /// - Returns: A date formatting object to format date to a string like "2021"
    static func yearTemplate(calendar: Calendar? = nil,
                             timeZone: TimeZone? = nil,
                             locale: Locale? = nil) -> DateFormatting {
        return fromTemplate("yyyy",
                            calendar: calendar,
                            timeZone: timeZone,
                            locale: locale)
    }
    
    /// Return a date formatting object using year and month components template
    /// - Parameters:
    ///   - calendar: The calendar for the date format
    ///   - timeZone: The time zone for the date fomat
    ///   - locale: The locale for the date format
    /// - Returns: A date formatting object to format date to a string like "November 2021"
    static func monthTemplate(calendar: Calendar? = nil,
                             timeZone: TimeZone? = nil,
                             locale: Locale? = nil) -> DateFormatting {
        return fromTemplate("MMMyyyy",
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
