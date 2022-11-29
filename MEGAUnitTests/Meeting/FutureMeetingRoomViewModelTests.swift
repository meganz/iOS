import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class FutureMeetingRoomViewModelTests: XCTestCase {
    
    func testComputedProperty_title() {
        let title = "Meeting Title"
        let scheduledMeeting = ScheduledMeetingEntity(title: title)
        let viewModel = FutureMeetingRoomViewModel(scheduledMeeting: scheduledMeeting)
        XCTAssert(viewModel.title == title)
    }
    
    func testComputedProperty_time() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        guard let startDate = dateFormatter.date(from: "2015-04-01T11:42:00") else {
            return
        }

        let endDate = startDate.advanced(by: 3600)
        
        let scheduledMeeting = ScheduledMeetingEntity(startDate: startDate, endDate: endDate)
        let viewModel = FutureMeetingRoomViewModel(scheduledMeeting: scheduledMeeting)
        XCTAssertTrue(viewModel.time == "11:42 AM - 12:42 PM" || viewModel.time == "11:42 - 12:42")
    }
}
