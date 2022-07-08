import XCTest
@testable import MEGA

final class StatsRepositoryTests: XCTestCase {
    
    func testSendEvent_onMediaDiscovery_shouldReturnTrue() throws {
        let sdk = MockSDK()
        let repo = StatsRepository(sdk: sdk)
        
        repo.sendStatsEvent(StatsEventEntity.clickMediaDiscovery)
        
        XCTAssertTrue(sdk.hasSendEventCalled)
    }
}


final fileprivate class MockSDK: MEGASdk {
    var hasSendEventCalled = false
    
    override func sendEvent(_ eventType: Int, message: String) {
        hasSendEventCalled = true
    }
}
