import XCTest
@testable import MEGA
import MEGADomain

final class StatsRepositoryTests: XCTestCase {
    
    func testSendEvent_onMediaDiscovery_shouldReturnTrue() throws {
        let sdk = MockSdk()
        let repo = StatsRepository(sdk: sdk)
        
        repo.sendStatsEvent(StatsEventEntity.clickMediaDiscovery)
        
        XCTAssertTrue(sdk.isLastSentEvent(eventType: 99304, message: "Media Discovery Option Tapped"))
    }
}
