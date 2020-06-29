import Foundation

enum DateTemplateFormat {
    /// Monday Jun 1, 2020
    case dateMediumWithWeekday

    fileprivate var style: StringTemplateStyle {
        switch self {
        case .dateMediumWithWeekday:
            return StringTemplateStyle(dateFormat: "EEEE MMM dd, yyyy")
        }
    }
}

enum DateStyleFormat {
    /// Jun 1, 2020 or "Tomorrow", "Today", "Yesterday" when relative is `true`
    case dateMedium(isRelative: Bool)

    fileprivate var style: DateFormatStyle {
        switch self {
        case .dateMedium(let relative):
            return DateFormatStyle(dateStyle: .medium, timeStyle: .none, relativeDateFormatting: relative)
        }
    }
}

/// A  date formatter pool that holds date formatter used in MEGA. As `DateFormatter` is a heavy object, so making a cache pool to hold popular
/// date formatters saving time.
/// NOTE: This shared object is *NOT* thread safe.
final class DateFormatterPool {

    // MARK: - Cache for date formatter

    private lazy var stringTemplateFormatterCache: [StringTemplateStyle: DateFormatter] = [:]

    private lazy var styleFormatterCache: [DateFormatStyle: DateFormatter] = [:]

    // MARK: - Static

    static var shared = DateFormatterPool()

    // MARK: - Lifecycles

    private init() {}

    // MARK: - Getting a date formatter by `styles`

    /// Returns a date formatter with given string template formatting. It search for cache by given `formatting`, and return immediatly. If not found,
    /// create a new one and save to cache.
    /// NOTE: As `DateFormatter` is an reference object, do *NOT* modify any property while using.
    /// - Parameter formattingStyle: A struct that holds date formatting template.
    /// - Returns: A date formatter.
    func dateFormatter(of formattingStyle: DateTemplateFormat) -> DateFormatting {
        if let cachedStyle = stringTemplateFormatterCache[formattingStyle.style] {
            return cachedStyle
        }
        let styleFormatter = formattingStyle.style.buildDateFormatter()
        stringTemplateFormatterCache[formattingStyle.style] = styleFormatter
        return styleFormatter
    }

    /// Returns a date formatter with given string formatting style. It search for cache by given `style`, and return immediatly. If not found,
    /// create a new one and save to cache.
    /// NOTE: As `DateFormatter` is an reference object, do *NOT* modify any property while using.
    /// - Parameter formattingStyle: A struct that holds date formatting styles.
    /// - Returns: A date formatter.
    func dateFormatter(of formattingStyle: DateStyleFormat) -> DateFormatting {
        if let cachedStyle = styleFormatterCache[formattingStyle.style] {
            return cachedStyle
        }
        let styleFormatter = formattingStyle.style.buildDateFormatter()
        styleFormatterCache[formattingStyle.style] = styleFormatter
        return styleFormatter
    }
}

// MARK: - `DateFormatter` creating configurations

/// A protocol tells who implements this should be able to provide `DateFormatter`
private protocol DateFormatterProvidable {
    func buildDateFormatter() -> DateFormatter
}

/// A template string style configuration
fileprivate struct StringTemplateStyle: Hashable {
    typealias FormatString = String

    let calendar: Calendar = .current
    let dateFormat: FormatString
}

extension StringTemplateStyle: DateFormatterProvidable {
    func buildDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.calendar = calendar
        return formatter
    }
}

/// A formatter provided style configuration
fileprivate struct DateFormatStyle: Hashable {

    let calendar: Calendar = .current
    let dateStyle: DateFormatter.Style
    let timeStyle: DateFormatter.Style

    /// If a date formatter uses relative date formatting, where possible it replaces the date component of its output with a phrase—such as
    ///  “today” or “tomorrow”—that indicates a relative date. The available phrases depend on the locale for the date formatter; whereas,
    ///  for dates in the future, English may only allow “tomorrow,” French may allow “the day after the day after tomorrow,”
    let relativeDateFormatting: Bool
}

extension DateFormatStyle: DateFormatterProvidable {

    func buildDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.doesRelativeDateFormatting = relativeDateFormatting
        return formatter
    }
}
