import Foundation

public extension DateFormatter {
    
    // MARK: - Relative date formatter, e.g. date in the next day will be "Tomorrow" etc.
    
    /// `Yesterday`,  `Today`, `Tomorrow`    /   `hoy`, `mañana`, `pasado mañana`    /   `昨天`, `今天`,  `明天`,  `后天`
    @objc static func dateRelativeShort(calendar: Calendar? = nil,
                                         timeZone: TimeZone? = nil,
                                         locale: Locale? = nil) -> DateFormatting {
        systemDateFormatter(dateStyle: .short,
                            timeStyle: .none,
                            isRelative: true,
                            calendar: calendar,
                            timeZone: timeZone,
                            locale: locale)
    }

    /// `Yesterday`,  `Today`, `Tomorrow`    /   `hoy`, `mañana`, `pasado mañana`    /   `昨天`, `今天`,  `明天`,  `后天`
    @objc static func dateRelativeMedium(calendar: Calendar? = nil,
                                         timeZone: TimeZone? = nil,
                                         locale: Locale? = nil) -> DateFormatting {
        systemDateFormatter(dateStyle: .medium,
                            timeStyle: .none,
                            isRelative: true,
                            calendar: calendar,
                            timeZone: timeZone,
                            locale: locale)
    }
    
    /// `Yesterday`,  `Today`, `Tomorrow`    /   `hoy`, `mañana`, `pasado mañana`    /   `昨天`, `今天`,  `明天`,  `后天`
    @objc static func dateRelativeLong(calendar: Calendar? = nil,
                                       timeZone: TimeZone? = nil,
                                       locale: Locale? = nil) -> DateFormatting {
        systemDateFormatter(dateStyle: .long,
                            timeStyle: .none,
                            isRelative: true,
                            calendar: calendar,
                            timeZone: timeZone,
                            locale: locale)
    }
    
    /// `Yesterday`,  `Today`, `Tomorrow`    /   `hoy`, `mañana`, `pasado mañana`    /   `昨天`, `今天`,  `明天`,  `后天`
    @objc static func dateRelativeFull(calendar: Calendar? = nil,
                                       timeZone: TimeZone? = nil,
                                       locale: Locale? = nil) -> DateFormatting {
        systemDateFormatter(dateStyle: .full,
                            timeStyle: .none,
                            isRelative: true,
                            calendar: calendar,
                            timeZone: timeZone,
                            locale: locale)
    }
}

// MARK: - Privates

fileprivate func systemDateFormatter(dateStyle: DateFormatter.Style,
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
