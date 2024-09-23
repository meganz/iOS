import Foundation

struct RecentlyWatchedVideosSectionDateConfiguration {
    let calendar: Calendar
    let timeZone: TimeZone?
    let locale: Locale?
    
    init(
        calendar: Calendar = .autoupdatingCurrent,
        timeZone: TimeZone? = nil,
        locale: Locale? = nil
    ) {
        self.calendar = calendar
        self.timeZone = timeZone
        self.locale = locale
    }
}
