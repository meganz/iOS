import Foundation

public extension DateFormatter {

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
    
    /// `1 Jan 1970 at 15:32`, `1 ene 1970 15:32`, `1970年1月1日 15:32`
    @objc static func dateMediumTimeShort(
        calendar: Calendar? = nil,
        timeZone: TimeZone? = nil,
        locale: Locale? = nil
    ) -> DateFormatting {
        systemDateFormatter(dateStyle: .medium,
                            timeStyle: .short,
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
    
    /// `15:32`
    @objc static func timeShort(
        calendar: Calendar? = nil,
        timeZone: TimeZone? = nil,
        locale: Locale? = nil
    ) -> DateFormatting {
        systemDateFormatter(dateStyle: .none,
                            timeStyle: .short,
                            isRelative: false,
                            calendar: calendar,
                            timeZone: timeZone,
                            locale: locale)
    }
}

// MARK: - Privates

private func systemDateFormatter(
    dateStyle: DateFormatter.Style,
    timeStyle: DateFormatter.Style,
    isRelative: Bool,
    calendar: Calendar?,
    timeZone: TimeZone?,
    locale: Locale?
) -> DateFormatting {
    let style = DateStyle.dateStyleFactory.systemStyle(ofDateStyle: dateStyle,
                                                       timeStyle: timeStyle,
                                                       relativeDateFormatting: isRelative,
                                                       calendar: calendar,
                                                       timeZone: timeZone,
                                                       locale: locale)
    return DateFormatterPool.shared.dateFormatter(of: style)
}
