import Foundation

extension DateFormatter {

    // MARK: - Date Formatter

    /// Monday Jun 1, 2020
    static var dateMediumWithWeekday: DateFormatter {
        DateFormatterPool.shared.dateFormatter(of: .dateMediumWithWeekday)
    }

    /// Jun 1, 2020
    static var dateMedium: DateFormatter {
        DateFormatterPool.shared.dateFormatter(of: .dateMedium(isRelative: false))
    }

    // MARK: - Relative date formatter, e.g. date in the next day will be "Tomorrow" etc.

    /// Jun 1, 2020 or "Tomorrow", "Today", "Yesterday"
    static var dateMediumRelative: DateFormatter {
        DateFormatterPool.shared.dateFormatter(of: .dateMedium(isRelative: true))
    }
}
