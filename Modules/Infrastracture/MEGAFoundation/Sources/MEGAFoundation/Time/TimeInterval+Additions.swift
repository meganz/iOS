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
}
