import Foundation

public extension TimeInterval {
    var timeString: String {
        if #available(iOS 16.0, *) {
            let duration: Duration = .seconds(Int(self))
            if self >= 3600 {
                return duration.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 2)))
            } else {
                return duration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
            }
        } else {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = (self >= 3600) ? [.hour, .minute, .second] : [.minute, .second]
            formatter.unitsStyle = .positional
            formatter.zeroFormattingBehavior = .pad
            return formatter.string(from: self) ?? "00:00"
        }
    }
}
