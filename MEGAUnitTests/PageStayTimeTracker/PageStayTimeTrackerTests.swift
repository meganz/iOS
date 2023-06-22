@testable import MEGA
import XCTest

final class PageStayTimeTrackerTests: XCTestCase {

    func testPageStay_withDuration11s_shouldReturnTrue() throws {
        var tracker = PageStayTimeTracker()
        let calendar = Calendar.current
        let startDate = Date()
        
        guard let endDate = calendar.date(byAdding: .second, value: 11, to: startDate) else { assertionFailure("Unexpected nil"); return }
        
        tracker.start(on: startDate)
        tracker.end(on: endDate)
        
        let duration = tracker.duration
        
        XCTAssertTrue(duration == 11)
    }
}
