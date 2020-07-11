import Foundation

extension DateFormatter {

    // MARK: - Formatter Custom Template Style

    /// Monday Jun 1, 2020
    static func dateMediumWithWeekday(calendar: Calendar? = nil,
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
    static func dateMediumSystem(calendar: Calendar? = nil,
                                 timeZone: TimeZone? = nil,
                                 locale: Locale? = nil) -> DateFormatting {
        let style = DateStyle.dateStyleFactory.systemStyle(ofDateStyle: .medium,
                                                           timeStyle: .none,
                                                           relativeDateFormatting: false,
                                                           calendar: calendar,
                                                           timeZone: timeZone,
                                                           locale: locale)
        return DateFormatterPool.shared.dateFormatter(of: style)
    }

    // MARK: - Relative date formatter, e.g. date in the next day will be "Tomorrow" etc.

    /// `Yesterday`,  `Today`, `Tomorrow`    /   `hoy`, `mañana`, `pasado mañana`    /   `昨天`, `今天`,  `明天`,  `后天`
    static func relativeDateMedium(calendar: Calendar? = nil,
                                   timeZone: TimeZone? = nil,
                                   locale: Locale? = nil) -> DateFormatting {
        let style = DateStyle.dateStyleFactory.systemStyle(ofDateStyle: .medium,
                                                         timeStyle: .none,
                                                         relativeDateFormatting: true,
                                                         calendar: calendar,
                                                         timeZone: timeZone,
                                                         locale: locale)
        return DateFormatterPool.shared.dateFormatter(of: style)
    }
}
