
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
}
