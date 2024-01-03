@testable import Video
import XCTest

final class VideoDurationFormatterTests: XCTestCase {
    
    func testFormatDuration_ZeroSecond_deliversCorrectDurationFormat() {
        let formatted = VideoDurationFormatter.formatDuration(seconds: 0)
        
        XCTAssertEqual(formatted, "00:00:00")
    }
    
    func testFormatDuration_OneSecond_deliversCorrectDurationFormat() {
        let formatted = VideoDurationFormatter.formatDuration(seconds: 1)
        
        XCTAssertEqual(formatted, "00:00:01")
    }

    func testFormatDuration_OneMinute_deliversCorrectDurationFormat() {
        let formatted = VideoDurationFormatter.formatDuration(seconds: 60)
        
        XCTAssertEqual(formatted, "00:01:00")
    }

    func testFormatDuration_OneHour_deliversCorrectDurationFormat() {
        let formatted = VideoDurationFormatter.formatDuration(seconds: 3600)
        
        XCTAssertEqual(formatted, "01:00:00")
    }

    func testFormatDuration_OneHourOneMinuteOneSecond_deliversCorrectDurationFormat() {
        let formatted = VideoDurationFormatter.formatDuration(seconds: 3661)
        
        XCTAssertEqual(formatted, "01:01:01")
    }

    func testFormatDuration_TenHoursFiftyNineMinutesFiftyNineSeconds_deliversCorrectDurationFormat() {
        let formatted = VideoDurationFormatter.formatDuration(seconds: 35999)
        
        XCTAssertEqual(formatted, "09:59:59")
    }

    func testFormatDuration_LargeDuration_deliversCorrectDurationFormat() {
        let formatted = VideoDurationFormatter.formatDuration(seconds: 123456)
        
        XCTAssertEqual(formatted, "34:17:36")
    }
}
