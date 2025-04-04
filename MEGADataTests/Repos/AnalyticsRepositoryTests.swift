@testable import MEGA
import MEGAAnalyticsDomain
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class AnalyticsRepositoryTests: XCTestCase {
    
    func testSendEvent_onMediaDiscovery_shouldReturnTrue() throws {
        let sdk = MockSdk()
        let repo = AnalyticsRepository(sdk: sdk)
        
        repo.sendAnalyticsEvent(.mediaDiscovery(.clickMediaDiscovery))
        
        XCTAssertEqual(sdk.sendEvent_Calls.count, 1)
        XCTAssertEqual(sdk.sendEvent_Calls.first?.eventType, 99304)
        XCTAssertEqual(sdk.sendEvent_Calls.first?.message, "Media Discovery Option Tapped")
        XCTAssertEqual(sdk.sendEvent_Calls.first?.addJourneyId, false)
        XCTAssertEqual(sdk.sendEvent_Calls.first?.viewId, nil)
    }
    
    func testSendEvent_withEventEntity_shouldAddJourneyId_withCorrectProperties() throws {
        let sdk = MockSdk()
        let repo = AnalyticsRepository(sdk: sdk)
        let expectedEvent = EventEntity(
            id: 12345,
            message: "Test Message",
            viewId: "TestViewId"
        )
        
        repo.sendAnalyticsEvent(expectedEvent)
        
        XCTAssertEqual(sdk.sendEvent_Calls.count, 1)
        XCTAssertEqual(sdk.sendEvent_Calls.first?.eventType, 12345)
        XCTAssertEqual(sdk.sendEvent_Calls.first?.message, "Test Message")
        XCTAssertEqual(sdk.sendEvent_Calls.first?.addJourneyId, true)
        XCTAssertEqual(sdk.sendEvent_Calls.first?.viewId, "TestViewId")
    }
}
