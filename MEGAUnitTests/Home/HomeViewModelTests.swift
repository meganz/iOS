@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
import XCTest

final class HomeViewModelTests: XCTestCase {
    func testDidStartSearchSession_tracksAnalyticsEvent() {
        let mockAnalyticsTracker = MockTracker()
        let sut = HomeViewModel(
            shareUseCase: MockShareUseCase(),
            tracker: mockAnalyticsTracker
        )
        sut.didStartSearchSession()
    }
}
