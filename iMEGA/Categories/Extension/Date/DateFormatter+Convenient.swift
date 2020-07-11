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

    /// `1/1/70`,       `1/1/70`,     `1970/1/1`
    @objc static func dateShort(calendar: Calendar? = nil,
                                timeZone: TimeZone? = nil,
                                locale: Locale? = nil) -> DateFormatting {
        systemDateFormatter(dateStyle: .short,
                            timeStyle: .none,
                            isRelative: false,
                            calendar: calendar,
                            timeZone: timeZone,
                            locale: locale)
    }

    /// `Jan 1, 1970`,  `1 ene 1970`,   `1970年1月1日`
    @objc static func dateMedium(calendar: Calendar? = nil,
                                 timeZone: TimeZone? = nil,
                                 locale: Locale? = nil) -> DateFormatting {
        systemDateFormatter(dateStyle: .medium,
                            timeStyle: .none,
                            isRelative: false,
                            calendar: calendar,
                            timeZone: timeZone,
                            locale: locale)
    }

    /// `January 1, 1970`, `1 de enero de 1970`, `1970年1月1日`
    @objc static func dateLong(calendar: Calendar? = nil,
                               timeZone: TimeZone? = nil,
                               locale: Locale? = nil) -> DateFormatting {
        systemDateFormatter(dateStyle: .long,
                            timeStyle: .none,
                            isRelative: false,
                            calendar: calendar,
                            timeZone: timeZone,
                            locale: locale)
    }

    /// `Thursday, January 1, 1970`, `jueves, 1 de enero de 1970`, `1970年1月1日 星期四`
    @objc static func dateFull(calendar: Calendar? = nil,
                               timeZone: TimeZone? = nil,
                               locale: Locale? = nil) -> DateFormatting {
        systemDateFormatter(dateStyle: .full,
                            timeStyle: .none,
                            isRelative: false,
                            calendar: calendar,
                            timeZone: timeZone,
                            locale: locale)
    }

    // MARK: - Relative date formatter, e.g. date in the next day will be "Tomorrow" etc.

    /// `Yesterday`,  `Today`, `Tomorrow`    /   `hoy`, `mañana`, `pasado mañana`    /   `昨天`, `今天`,  `明天`,  `后天`
    @objc static func dateRelativeMedium(calendar: Calendar? = nil,
                                         timeZone: TimeZone? = nil,
                                         locale: Locale? = nil) -> DateFormatting {
        systemDateFormatter(dateStyle: .medium, timeStyle: .none, isRelative: true, calendar: calendar, timeZone: timeZone, locale: locale)
    }

    // MARK: - Privates

    static func systemDateFormatter(dateStyle: DateFormatter.Style,
                                    timeStyle: DateFormatter.Style,
                                    isRelative: Bool,
                                    calendar: Calendar?,
                                    timeZone: TimeZone?,
                                    locale: Locale?) -> DateFormatting {
        let style = DateStyle.dateStyleFactory.systemStyle(ofDateStyle: dateStyle,
                                                           timeStyle: timeStyle,
                                                           relativeDateFormatting: isRelative,
                                                           calendar: calendar,
                                                           timeZone: timeZone,
                                                           locale: locale)
        return DateFormatterPool.shared.dateFormatter(of: style)
    }
}
