import Foundation

typealias MNZTimestap = Date

extension Date {

    /// Will return the starting time of current date on given calendar.
    /// - Parameter calendar: Calendar onn which the starting time of current instance based.
    /// - Returns: A `Timesamp` (`Date`)  of a calendar day that contains current date.
    func startOfDay(on calendar: Calendar) -> MNZTimestap? {
        calendar.dateInterval(of: .day, for: self)?.start
    }

    /// Will return starting timesamp with given `CalendarComponent` in the given `Calendar.`
    /// e.g. given current date is 31 May, 22:39, 2020, with the given calendar component `.day`, and calendar instance `Gregorian Calendar`,
    /// TimeZone `AEST`, Local `Australia`, it will return a timesamp - acutall a `Date` instance with `31 May, 00:00, 2020`
    /// (1590847200 since Jan 1, 1970 ) in `AEST`
    /// time zone.
    /// - Parameters:
    ///   - calendarComponent: The calendar component that erase the `Date` instrance's corrensponding property to 0.
    ///   - calendar: The calendar on which the starting timesamp of date based.
    /// - Returns: A `Timesamp` (`Date`)  of a given calendar component that contains current date.
    func startingTimestamp(with calendarComponent: Calendar.Component,
                           on calendar: Calendar) -> MNZTimestap? {
        calendar.dateInterval(of: calendarComponent, for: self)?.start
    }
}
