import XCTest
@testable import MEGA
import MEGADomain
import MEGAData
import MEGADataMock

final class AnalyticsRepositoryTests: XCTestCase {
    
    func testSendEvent_onMediaDiscovery_shouldReturnTrue() throws {
        let sdk = MockSdk()
        let repo = AnalyticsRepository(sdk: sdk)
        
        repo.sendAnalyticsEvent(.mediaDiscovery(.clickMediaDiscovery))
        
        XCTAssertTrue(sdk.isLastSentEvent(eventType: 99304, message: "Media Discovery Option Tapped"))
    }
}
