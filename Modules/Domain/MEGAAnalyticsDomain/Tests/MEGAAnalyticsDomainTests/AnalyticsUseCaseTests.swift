import MEGAAnalyticsDomain
import MEGAAnalyticsDomainMock
import XCTest

final class AnalyticsUseCaseTests: XCTestCase {
    func testSendEvent_shouldPassCorrectProperties() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsUseCase(analyticsRepo: repo)
        
        let expectedEvent = EventEntity(
            id: 12345,
            message: "Test Message",
            viewId: "TestViewId"
        )
        
        sut.sendEvent(expectedEvent)
        
        XCTAssertEqual(repo.sendAnalyticsEvent_Calls, [expectedEvent])
    }
}
