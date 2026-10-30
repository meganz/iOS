import Foundation
@testable import MEGAAudioPlayer
import Testing

struct TimeIntervalPlaybackPositionTests {

    @Test("Pads the minutes under an hour", arguments: [
        (TimeInterval(0), "00:00"),
        (20, "00:20"),
        (80, "01:20"),
        (294.7, "04:55"),
        (3423, "57:03"),
        (3599.4, "59:59")
    ])
    func padsMinutesUnderAnHour(time: TimeInterval, expected: String) {
        #expect(time.playbackPositionString == expected)
    }

    @Test("Shows unpadded hours from an hour up", arguments: [
        (TimeInterval(3599.6), "1:00:00"),
        (3723, "1:02:03"),
        (7023, "1:57:03"),
        (36000, "10:00:00")
    ])
    func showsHoursFromAnHourUp(time: TimeInterval, expected: String) {
        #expect(time.playbackPositionString == expected)
    }

    @Test("Reads a negative or non-finite time as zero", arguments: [-5, .nan, .infinity] as [TimeInterval])
    func clampsInvalidTimes(time: TimeInterval) {
        #expect(time.playbackPositionString == "00:00")
    }
}
