import Foundation

public extension NSDate {
    @objc func isToday() -> Bool {
        (self as Date).isToday(on: Calendar.autoupdatingCurrent)
    }
    
    @objc func isSameDayAs(date: NSDate) -> Bool {
        (self as Date).isSameDay(date: (date as Date))
    }
}
