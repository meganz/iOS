import Foundation

extension DateFormatter {

    // MARK: - Formatter Custom Template Style

    /// Monday Jun 1, 2020
    @objc static func dateMediumWithWeekday(calendar: Calendar? = nil,
                                      timeZone: TimeZone? = nil,
                                      locale: Locale? = nil) -> DateFormatting {
        let style = DateStyle.dateStyleFactory.templateStyle(fromTemplate: "EEEEMMMddyyyy",
                                                         calendar: calendar,
                                                         timeZone: timeZone,
                                                         locale: locale)
        return DateFormatterPool.shared.dateFormatter(of: style)
    }

    // MARK: - Formatter Style

    /// English -- `Jan 1, 1970`    Spanish -- `1 ene 1970`    Chinese -- `1970年1月1日`
    @objc static func dateMediumSystem(calendar: Calendar? = nil,
                                 timeZone: TimeZone? = nil,
                                 locale: Locale? = nil) -> DateFormatting {
        dateMedium(dateStyle: .medium, timeStyle: .none, isRelative: false)
    }

    // MARK: - Relative date formatter, e.g. date in the next day will be "Tomorrow" etc.

    /// `Yesterday`,  `Today`, `Tomorrow`    /   `hoy`, `mañana`, `pasado mañana`    /   `昨天`, `今天`,  `明天`,  `后天`
    @objc static func relativeDateMedium(calendar: Calendar? = nil,
                                   timeZone: TimeZone? = nil,
                                   locale: Locale? = nil) -> DateFormatting {
        dateMedium(dateStyle: .medium, timeStyle: .none, isRelative: true)
    }

    // MARK: - Privates

    static func dateMedium(dateStyle: DateFormatter.Style,
                           timeStyle: DateFormatter.Style,
                           isRelative: Bool,
                           calendar: Calendar? = nil,
                           timeZone: TimeZone? = nil,
                           locale: Locale? = nil) -> DateFormatting {
        let style = DateStyle.dateStyleFactory.systemStyle(ofDateStyle: dateStyle,
                                                           timeStyle: timeStyle,
                                                           relativeDateFormatting: isRelative,
                                                           calendar: calendar,
                                                           timeZone: timeZone,
                                                           locale: locale)
        return DateFormatterPool.shared.dateFormatter(of: style)
    }
}
