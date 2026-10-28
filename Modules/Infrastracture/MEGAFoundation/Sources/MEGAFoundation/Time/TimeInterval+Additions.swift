import Foundation

public extension TimeInterval {
    var timeString: String {
        let duration: Duration = .seconds(Int(self))
        if self >= 3600 {
            return duration.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 2)))
        } else {
            return duration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
        }
    }

    /// Like `timeString` without padding the leading unit, and rounded to the nearest
    /// second rather than truncated: `4:55`, `1:02:03`. A non-finite value reads `0:00`.
    var compactTimeString: String {
        guard isFinite else { return "0:00" }
        let seconds = rounded()
        let duration: Duration = .seconds(seconds)
        if seconds >= 3600 {
            return duration.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 1)))
        } else {
            return duration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1)))
        }
    }
}
