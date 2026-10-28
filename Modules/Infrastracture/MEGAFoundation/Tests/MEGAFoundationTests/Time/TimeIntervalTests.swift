import XCTest

final class TimeIntervalTests: XCTestCase {
    func testTimeString_longInterval() {
        let timeInterval: TimeInterval = 3661 // 1 hour, 1 minute, and 1 second
        let sut = timeInterval.timeString
        XCTAssertEqual(sut, "01:01:01")
    }
    
    func testTimeString_shortInterval() {
        let timeInterval: TimeInterval = 61 // 1 minute and 1 second
        let sut = timeInterval.timeString
        XCTAssertEqual(sut, "01:01")
    }
    
    func testTimeString_zeroInterval() {
        let timeInterval: TimeInterval = 0
        let sut = timeInterval.timeString
        XCTAssertEqual(sut, "00:00")
    }

    func testCompactTimeString_longInterval() {
        let timeInterval: TimeInterval = 3661 // 1 hour, 1 minute, and 1 second
        let sut = timeInterval.compactTimeString
        XCTAssertEqual(sut, "1:01:01")
    }

    func testCompactTimeString_shortInterval() {
        let timeInterval: TimeInterval = 295 // 4 minutes and 55 seconds
        let sut = timeInterval.compactTimeString
        XCTAssertEqual(sut, "4:55")
    }

    func testCompactTimeString_zeroInterval() {
        let timeInterval: TimeInterval = 0
        let sut = timeInterval.compactTimeString
        XCTAssertEqual(sut, "0:00")
    }

    func testCompactTimeString_roundsToNearestSecond() {
        XCTAssertEqual(TimeInterval(294.7).compactTimeString, "4:55")
        XCTAssertEqual(TimeInterval(294.4).compactTimeString, "4:54")
    }

    func testCompactTimeString_roundingUpToAnHour_includesHours() {
        XCTAssertEqual(TimeInterval(3599.6).compactTimeString, "1:00:00")
    }

    func testCompactTimeString_nonFiniteInterval() {
        XCTAssertEqual(TimeInterval.nan.compactTimeString, "0:00")
        XCTAssertEqual(TimeInterval.infinity.compactTimeString, "0:00")
    }
}
