import Foundation

/// Configuration for formatting date strings in the "Recently Watched Videos" section.
///
/// This structure allows for customizing how dates are formatted and displayed by using a specific date format template,
/// calendar, time zone, and locale settings. It uses the `Unicode Date Field Symbol Table` standard for defining date components.
///
/// Example format: `"E, d MMM yyyy"` could result in `"Fri, 22 Oct 2023"`.
struct RecentlyWatchedVideosSectionDateConfiguration {
    
    /// A date format template that specifies how the date should be formatted.
    ///
    /// The template follows the `Unicode Date Field Symbol Table` standard for specifying date components.
    /// Common symbols include:
    /// - `E`: Day of the week (e.g., Mon, Tue)
    /// - `d`: Day of the month (e.g., 1, 2)
    /// - `MMM`: Abbreviated month name (e.g., Jan, Feb)
    /// - `yyyy`: Full year (e.g., 2023)
    ///
    /// You can customize this template based on your requirements for formatting date strings.
    let dateFormatTemplate: String
    
    /// The calendar instance to use for date calculations.
    ///
    /// This specifies how dates should be calculated, accounting for different calendars (Gregorian, Islamic, etc.).
    /// Defaults to the user’s auto-updating calendar (`.autoupdatingCurrent`), which adjusts based on the user’s system settings.
    let calendar: Calendar
    
    /// The time zone to use for formatting the date, or `nil` to use the system’s default time zone.
    ///
    /// If `nil`, the current system time zone will be used. You can provide a specific time zone to format dates for a particular region.
    let timeZone: TimeZone?
    
    /// The locale to use for formatting the date, or `nil` to use the system’s default locale.
    ///
    /// Locale affects the language and regional formatting (e.g., month names, week start day).
    /// If `nil`, the current system locale is used, which reflects the user's settings.
    let locale: Locale?
    
    /// Initializes a configuration for date formatting in the "Recently Watched Videos" section.
    ///
    /// - Parameters:
    ///   - dateFormatTemplate: A template for formatting dates using the `Unicode Date Field Symbol Table`. Defaults to `"E, d MMM yyyy"`.
    ///   - calendar: A calendar instance used for date calculations. Defaults to `.autoupdatingCurrent`, which adjusts based on user settings.
    ///   - timeZone: The time zone used for date formatting, or `nil` to use the system's default time zone. Defaults to `nil`.
    ///   - locale: The locale used for formatting the date string, or `nil` to use the system's default locale. Defaults to `nil`.
    init(
        dateFormatTemplate: String = "E, d MMM yyyy",
        calendar: Calendar = .autoupdatingCurrent,
        timeZone: TimeZone? = nil,
        locale: Locale? = nil
    ) {
        self.dateFormatTemplate = dateFormatTemplate
        self.calendar = calendar
        self.timeZone = timeZone
        self.locale = locale
    }
}
