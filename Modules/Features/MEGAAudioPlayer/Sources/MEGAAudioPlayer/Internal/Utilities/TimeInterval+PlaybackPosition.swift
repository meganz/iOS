import Foundation

extension TimeInterval {
    /// A playback position or remaining time, the way the scrubber and the queue both show it: padded
    /// minutes (`00:20`), or unpadded hours from an hour up (`1:05:00`). Rounded to the nearest
    /// second; a negative or non-finite value reads as zero.
    var playbackPositionString: String {
        let seconds = isFinite ? Swift.max(self, 0).rounded() : 0
        let pattern: Duration.TimeFormatStyle.Pattern = seconds >= 3600
            ? .hourMinuteSecond(padHourToLength: 1)
            : .minuteSecond(padMinuteToLength: 2)
        return Duration.seconds(seconds).formatted(.time(pattern: pattern))
    }
}
