import Foundation
import MEGASwift

public enum DateStyle {
    public static let dateStyleFactory: some DateStyleFactory = DateStyleFactoryImpl()
}

public protocol DateStyleFactory: Sendable {

    func templateStyle(
        fromTemplate template: String,
        calendar: Calendar?,
        timeZone: TimeZone?,
        locale: Locale?) -> DateStyle.StringTemplateStyle

    func systemStyle(
        ofDateStyle dateStyle: DateFormatter.Style,
        timeStyle: DateFormatter.Style,
        relativeDateFormatting: Bool?,
        calendar: Calendar?,
        timeZone: TimeZone?,
        locale: Locale?) -> DateStyle.DateFormatStyle
}

public struct DateStyleFactoryImpl: DateStyleFactory {

    public func templateStyle(fromTemplate template: String, calendar: Calendar?, timeZone: TimeZone?, locale: Locale?) -> DateStyle.StringTemplateStyle {
        DateStyle.StringTemplateStyle(dateFormat: template, calendar: calendar, timeZone: timeZone, locale: locale)
    }

    public func systemStyle(ofDateStyle dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, relativeDateFormatting: Bool?, calendar: Calendar?, timeZone: TimeZone?, locale: Locale?) -> DateStyle.DateFormatStyle {
        DateStyle.DateFormatStyle(dateStyle: dateStyle, timeStyle: timeStyle, relativeDateFormatting: relativeDateFormatting, calendar: calendar, timeZone: timeZone, locale: locale)
    }

}

/// A  date formatter pool that holds date formatter used in MEGA. As `DateFormatter` is a heavy object, so making a cache pool to hold popular
/// date formatters saving time.
/// NOTE: This shared object is thread safe.
public final class DateFormatterPool: @unchecked Sendable {

    // MARK: - Cache for date formatter

    @Atomic private var stringTemplateFormatterCache = [DateStyle.StringTemplateStyle: DateFormatter]()

    @Atomic private var styleFormatterCache = [DateStyle.DateFormatStyle: DateFormatter]()

    // MARK: - Static

    static let shared = DateFormatterPool()

    // MARK: - Lifecycles

    private init() {}

    // MARK: - Getting a date formatter by `styles`

    /// Returns a date formatter with given string template formatting. It search for cache by given `formatting`, and return immediately. If not found,
    /// create a new one and save to cache.
    /// NOTE: As `DateFormatter` is an reference object, do *NOT* modify any property while using.
    /// - Parameter formattingStyle: A struct that holds date formatting template.
    /// - Returns: A date formatter.
    func dateFormatter(of formattingStyle: DateStyle.StringTemplateStyle) -> some DateFormatting {
        if let cachedStyle = stringTemplateFormatterCache[formattingStyle] {
            return cachedStyle
        }
        let styleFormatter = formattingStyle.buildDateFormatter()
        $stringTemplateFormatterCache.mutate {
            $0[formattingStyle] = styleFormatter
        }
        return styleFormatter
    }

    /// Returns a date formatter with given string formatting style. It search for cache by given `style`, and return immediately. If not found,
    /// create a new one and save to cache.
    /// NOTE: As `DateFormatter` is an reference object, do *NOT* modify any property while using.
    /// - Parameter formattingStyle: A struct that holds date formatting styles.
    /// - Returns: A date formatter.
    func dateFormatter(of formattingStyle: DateStyle.DateFormatStyle) -> some DateFormatting {
        if let cachedStyle = styleFormatterCache[formattingStyle] {
            return cachedStyle
        }
        let styleFormatter = formattingStyle.buildDateFormatter()
        $styleFormatterCache.mutate {
            $0[formattingStyle] = styleFormatter
        }
        return styleFormatter
    }
}

// MARK: - `DateFormatter` creating configurations

/// A protocol tells who implements this should be able to provide `DateFormatter`
private protocol DateFormatterProvidable {
    func buildDateFormatter() -> DateFormatter
}

public extension DateStyle {
    /// A template string style configuration
    struct StringTemplateStyle: Hashable {
        typealias FormatString = String

        let dateFormat: FormatString
        var calendar: Calendar?
        var timeZone: TimeZone?
        var locale: Locale?
    }
}

extension DateStyle.StringTemplateStyle: DateFormatterProvidable {
    func buildDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        if let calendar = calendar { formatter.calendar = calendar }
        if let locale = locale { formatter.locale = locale }
        if let timeZone = timeZone { formatter.timeZone = timeZone }
        formatter.setLocalizedDateFormatFromTemplate(dateFormat)
        return formatter
    }
}

public extension DateStyle {
    /// A formatter provided style configuration
    struct DateFormatStyle: Hashable {

        let dateStyle: DateFormatter.Style
        let timeStyle: DateFormatter.Style

        /// If a date formatter uses relative date formatting, where possible it replaces the date component of its output with a phrase—such as
        ///  “today” or “tomorrow”—that indicates a relative date. The available phrases depend on the locale for the date formatter; whereas,
        ///  for dates in the future, English may only allow “tomorrow,” French may allow “the day after the day after tomorrow,”
        var relativeDateFormatting: Bool?
        var calendar: Calendar?
        var timeZone: TimeZone?
        var locale: Locale?
    }
}

extension DateStyle.DateFormatStyle: DateFormatterProvidable {

    func buildDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        if let calendar = calendar { formatter.calendar = calendar }
        if let locale = locale { formatter.locale = locale }
        if let timeZone = timeZone { formatter.timeZone = timeZone }
        if let relativeDateFormatting = relativeDateFormatting {
            formatter.doesRelativeDateFormatting = relativeDateFormatting
        }
        return formatter
    }
}
