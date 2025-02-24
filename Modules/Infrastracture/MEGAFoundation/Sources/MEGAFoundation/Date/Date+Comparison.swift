import Foundation

public extension Date {

    typealias NumberOfDays = Int

    /// Will return a positive number which indicates calendar days on specified calendar from `self` to a given *future* date.
    /// Discussion: This function is used to calculate distance of calendar days to a *future* date which means
    /// at least `futureDate` is later than or equal to current instance, so that the `numberOfDays` will be a positive number,
    /// or else, nil will be return.
    /// - Parameters:
    ///   - futureDate: A date in the future on which this distance of days will be calculated.
    ///   - calendar: A calendar object on which the calendar days to be based.
    /// - Returns:
    func dayDistance(toFutureDate futureDate: Date, on calendar: Calendar) -> NumberOfDays? {
        guard futureDate >= self else {
            assertionFailure("\(futureDate) should be later than now - \(Date()) ")
            return nil
        }
        return calendar.dateComponents([.day], from: self, to: futureDate).day
    }

    /// Will return a positive number which indicates calendar days on specified calendar from `self` to a given *past* date.
    /// Discussion: This function is used to calculate distance of calendar days to a *past* date which means
    /// at least `pastDate` is earlier than or equal to current instance, so that the `numberOfDays` will be a positive number,
    /// or else, nil will be return.
    /// - Parameters:
    ///   - pastDate: A date in the future on which this distance of days will be calculated based.
    ///   - calendar: A calendar object on which the calendar days to be based on.
    /// - Returns:
    func dayDistance(toPastDate pastDate: Date, on calendar: Calendar) -> NumberOfDays? {
        guard pastDate <= self else {
            assertionFailure("\(pastDate) should be earlier than now - \(Date()) ")
            return nil
        }
        return calendar.dateComponents([.day], from: self, to: pastDate).day.map(abs)
    }
}

public extension Date {

    /// Indicates the invoker on the given calendar is *Today*.
    /// - Parameter calendar: The calendar which is used to consult *Today* information from.
    /// - Returns: True if invoker is today on calendar, else false.
    func isToday(on calendar: Calendar) -> Bool {
        calendar.isDateInToday(self)
    }

    /// Indicates the invoker on the given calendar is *Tomorrow*.
    /// - Parameter calendar: The calendar which is used to consult  *Tomorrow* information from.
    /// - Returns: True if invoker is tomorrow on calendar, else false.
    func isTomorrow(on calendar: Calendar) -> Bool {
        calendar.isDateInTomorrow(self)
    }
    
    func isYesterday(on calendar: Calendar) -> Bool {
        calendar.isDateInYesterday(self)
    }
    
    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    /// Returns the number of days the receiver's date is earlier than the provided
    /// comparison date, 0 if the receiver's date is later than or equal to the provided comparison date.
    /// - Parameter date: Provided date for comparison
    /// - Returns: The number of days
    func daysEarlier(than date: Date) -> Int {
        abs(min(days(from: date), 0))
    }
    
    /// Returns an Int representing the amount of time in days between the receiver and
    /// the provided date.
    ///
    /// If the receiver is earlier than the provided date, the returned value will be negative.
    /// Uses the default Gregorian calendar
    ///
    /// - Parameter date: The provided date for comparison
    /// - Returns: The days between receiver and provided date
    func days(from date: Date) -> Int {
        let calendar = Calendar.autoupdatingCurrent
        
        let earliest = earlierDate(date)
        let latest = (earliest == self) ? date : self
        let multiplier = (earliest == self) ? -1 : 1
        let components = calendar.dateComponents([.day], from: earliest, to: latest)
        return multiplier * (components.day ?? 0)
    }
    
    /// Return the earlier of two dates, between self and a given date.
    /// - Parameter date: The date to compare to self
    /// - Returns: The date that is earlier
    func earlierDate(_ date: Date) -> Date {
        (timeIntervalSince1970 <= date.timeIntervalSince1970) ? self : date
    }
    
    func isSameDay(date: Date) -> Bool {
        isSame(date: date, components: [.day, .month, .year])
    }
    
    func isSameMinute(date: Date) -> Bool {
        isSame(date: date, components: [.minute, .day, .month, .year])
    }
    
    func isSame(date: Date, components: Set<Calendar.Component>) -> Bool {
        let thisDateComponents = Calendar.current.dateComponents(components, from: self)
        let otherDateComponents = Calendar.current.dateComponents(components, from: date)
        let results = components.map { thisDateComponents.value(for: $0) == otherDateComponents.value(for: $0) }
        return !results.contains(false)
    }
}
