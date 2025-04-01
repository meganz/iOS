import Foundation
@testable import MEGAFoundation
import XCTest

final class TimeZone_Additions: XCTestCase {
    func test_TimeZoneGMT_shouldReturnZeroSecondsFromGMT() {
        let gmtTimeZone = TimeZone.GMT
        XCTAssertEqual(gmtTimeZone.secondsFromGMT(), 0, "GMT should return a TimeZone with 0 seconds from GMT")
    }

    func test_TimeZoneGMT_shouldReturnGMTIdentifier() {
        let gmtTimeZone = TimeZone.GMT
        XCTAssertEqual(gmtTimeZone.identifier, "GMT", "GMT should return a TimeZone with the identifier 'GMT'")
    }
}
